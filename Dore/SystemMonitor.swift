import Foundation
import Observation
import Darwin
import IOKit.ps

struct MetricSample: Identifiable {
    let id = UUID()
    let date: Date
    let cpu: Double
    let memory: Double
    let download: Double
    let upload: Double
}

@MainActor @Observable
final class SystemMonitor {
    var cpu = 0.0
    var hardware = HardwareMetrics(values: [:])
    var systemPower: Double?
    var powerPeak = 0.0
    var temperatureSensors: [TemperatureSensor] = []
    var cpuTemperature: Double? {
        let values = temperatureSensors.filter { $0.group == .cpu }.map(\.value)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
    var temperatureDiagnostic = "尚未读取"
    private var temperaturePeaks: [String: Double] = [:]
    private let helperClient = DoreHelperClient()
    var memoryUsed = 0.0
    var memoryWired = 0.0
    var memoryCompressed = 0.0
    let memoryTotal = Double(ProcessInfo.processInfo.physicalMemory)
    var diskTotal = 0.0
    var diskFree = 0.0
    var download = 0.0
    var upload = 0.0
    var battery: Double?
    var charging = false
    var onAC = true
    var samples: [MetricSample] = []
    var paused = false
    var lastUpdated: Date?
    var thermalState = ProcessInfo.processInfo.thermalState
    let chip = SystemMonitor.hardwareString("machdep.cpu.brand_string")
    let model = SystemMonitor.hardwareString("hw.model")
    let cores = ProcessInfo.processInfo.processorCount
    private var previousCPU: (UInt64, UInt64)?
    private var previousNetwork: (UInt64, UInt64, Date)?
    private var task: Task<Void, Never>?
    private var samplingGeneration = UUID()

    var memoryPercent: Double { memoryUsed / memoryTotal * 100 }
    var diskPercent: Double { diskTotal > 0 ? (diskTotal - diskFree) / diskTotal * 100 : 0 }
    var thermalDescription: String {
        switch thermalState {
        case .nominal: return "正常"
        case .fair: return "温暖"
        case .serious: return "较高"
        case .critical: return "过热"
        @unknown default: return "未知"
        }
    }

    func start() {
        guard task == nil else { return }
        sample()
        task = Task { [weak self] in
            while !Task.isCancelled {
                let seconds = max(1, UserDefaults.standard.object(forKey: "refreshInterval") as? Double ?? 2)
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled, let self else { return }
                if !self.paused { self.sample() }
            }
        }
    }

    func togglePause() {
        paused.toggle()
        samplingGeneration = UUID()
        previousCPU = nil
        previousNetwork = nil
        if !paused { sample() }
    }

    func sample() {
        guard !paused else { return }
        sampleCPU()
        let generation = samplingGeneration
        helperClient.request { [weak self] value, hardware, diagnostic in
            guard let self, !self.paused, self.samplingGeneration == generation else { return }
            self.temperatureSensors = value.map { reading in
                var reading = reading
                let peak = max(self.temperaturePeaks[reading.id] ?? reading.value, reading.value)
                self.temperaturePeaks[reading.id] = peak
                reading.peak = peak
                return reading
            }
            self.hardware = hardware
            let watts = hardware.systemPower
            self.systemPower = watts
            if let watts { self.powerPeak = max(self.powerPeak, watts) }
            self.temperatureDiagnostic = diagnostic
        }
        sampleMemory()
        sampleNetwork()
        if let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]) {
            diskTotal = Double(values.volumeTotalCapacity ?? 0)
            diskFree = Double(values.volumeAvailableCapacity ?? 0)
        }
        sampleBattery()
        thermalState = ProcessInfo.processInfo.thermalState
        let now = Date()
        lastUpdated = now
        samples.append(MetricSample(date: now, cpu: cpu, memory: memoryPercent, download: download, upload: upload))
        samples.removeAll { now.timeIntervalSince($0.date) > 300 }
    }

    private func sampleCPU() {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let ticks = info.cpu_ticks
        let idle = UInt64(ticks.2)
        let total = UInt64(ticks.0) + UInt64(ticks.1) + idle + UInt64(ticks.3)
        if let previousCPU, total > previousCPU.0, idle >= previousCPU.1 {
            cpu = min(100, max(0, (1 - Double(idle - previousCPU.1) / Double(total - previousCPU.0)) * 100))
        }
        previousCPU = (total, idle)
    }

    private func sampleMemory() {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        var pageSize: vm_size_t = 0
        host_page_size(host, &pageSize)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let page = Double(pageSize)
        memoryWired = Double(info.wire_count) * page
        memoryCompressed = Double(info.compressor_page_count) * page
        memoryUsed = min(memoryTotal, max(0, Double(info.active_count) * page + memoryWired + memoryCompressed - Double(info.purgeable_count) * page))
    }

    private func sampleNetwork() {
        var address: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&address) == 0 else { return }
        defer { freeifaddrs(address) }
        var cursor = address
        var received: UInt64 = 0
        var sent: UInt64 = 0
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }
            guard let addr = entry.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK),
                  let data = entry.pointee.ifa_data,
                  String(cString: entry.pointee.ifa_name).hasPrefix("en") else { continue }
            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            received += UInt64(stats.ifi_ibytes)
            sent += UInt64(stats.ifi_obytes)
        }
        let now = Date()
        if let previousNetwork {
            let elapsed = now.timeIntervalSince(previousNetwork.2)
            if elapsed > 0, received >= previousNetwork.0, sent >= previousNetwork.1 {
                download = Double(received - previousNetwork.0) / elapsed
                upload = Double(sent - previousNetwork.1) / elapsed
            }
        }
        previousNetwork = (received, sent, now)
    }

    private func sampleBattery() {
        battery = nil
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = description[kIOPSCurrentCapacityKey] as? Int,
                  let maximum = description[kIOPSMaxCapacityKey] as? Int, maximum > 0 else { continue }
            battery = Double(current) / Double(maximum) * 100
            charging = description[kIOPSIsChargingKey] as? Bool ?? false
            onAC = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
        }
    }

    nonisolated private static func hardwareString(_ name: String) -> String {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "Mac" }
        var bytes = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &bytes, &size, nil, 0) == 0 else { return "Mac" }
        return String(cString: bytes)
    }
}

func byteString(_ bytes: Double) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(max(0, bytes)), countStyle: .memory)
}

func rateString(_ bytes: Double) -> String {
    if bytes < 1_024 { return String(format: "%.0f B/s", bytes) }
    if bytes < 1_048_576 { return String(format: "%.1f KB/s", bytes / 1_024) }
    return String(format: "%.1f MB/s", bytes / 1_048_576)
}
