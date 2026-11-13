import Foundation
import IOKit

final class DoreHelper: NSObject, DoreHelperProtocol {
    private let reader = SMCSensorReader()
    private let energyReader = EnergyReader()
    private let queue = DispatchQueue(label: "io.iftech.Dore.hardware", qos: .utility)

    func readSensors(withReply reply: @escaping (Data?, String) -> Void) {
        queue.async { [self] in
            var values = reader.readAll()
            values["PSTR"] = reader.readSystemPower()
            values.merge(reader.readFans()) { _, new in new }
            values.merge(energyReader.read()) { _, new in new }
            values["GPU Utilization"] = readGPUUtilization()
            reply(try? JSONEncoder().encode(values), reader.diagnostic)
        }
    }

    private func readGPUUtilization() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        var readings: [Double] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard let stats = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, nil, 0)?.takeRetainedValue() as? [String: Any],
                  let number = stats["Device Utilization %"] as? NSNumber else { continue }
            let value = number.doubleValue
            if value.isFinite, (0...100).contains(value) { readings.append(value) }
        }
        // On multi-GPU machines this is the busiest accelerator, not a sum.
        return readings.max()
    }

    func readCPUTemperature(withReply reply: @escaping (NSNumber?, String) -> Void) {
        queue.async { [self] in
            let value = reader.read()
            reply(value.map(NSNumber.init(value:)), reader.diagnostic)
        }
    }
}
