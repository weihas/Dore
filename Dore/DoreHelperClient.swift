import Foundation

@MainActor
final class DoreHelperClient {
    private var connection: NSXPCConnection?
    private var connectionID: UUID?
    private var pending: (UUID, @MainActor ([TemperatureSensor], HardwareMetrics, String) -> Void)?
    private var timeout: Task<Void, Never>?

    func request(_ completion: @escaping @MainActor ([TemperatureSensor], HardwareMetrics, String) -> Void) {
        guard pending == nil else { return }
        let id = UUID()
        pending = (id, completion)
        if connection == nil {
            let connectionID = UUID()
            let connection = NSXPCConnection(serviceName: "io.iftech.Dore.DoreHelper")
            connection.remoteObjectInterface = NSXPCInterface(with: DoreHelperProtocol.self)
            connection.invalidationHandler = { [weak self] in
                Task { @MainActor in
                    guard let self, self.connectionID == connectionID else { return }
                    self.connection = nil
                    self.connectionID = nil
                    if let id = self.pending?.0 { self.finish(id, value: [], message: "硬件监控服务连接已关闭，将自动重试") }
                }
            }
            connection.interruptionHandler = { [weak self] in
                Task { @MainActor in
                    guard let self, self.connectionID == connectionID else { return }
                    self.resetConnection()
                    if let id = self.pending?.0 { self.finish(id, value: [], message: "硬件监控服务暂时中断，将自动重试") }
                }
            }
            connection.resume()
            self.connection = connection
            self.connectionID = connectionID
        }
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.fail(id, message: "硬件读取超时，将自动重试")
        }
        let proxy = connection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            let message = error.localizedDescription
            Task { @MainActor in self?.fail(id, message: "硬件监控服务不可用：\(message)") }
        } as? DoreHelperProtocol
        guard let proxy else {
            fail(id, message: "无法连接硬件监控服务")
            return
        }
        proxy.readSensors { [weak self] data, diagnostic in
            let values = data.flatMap { try? JSONDecoder().decode([String: Double].self, from: $0) } ?? [:]
            let sensors = values.compactMap { key, value -> TemperatureSensor? in
                guard key.hasPrefix("T"), value.isFinite, value > 0, value < 130 else { return nil }
                return TemperatureSensor(id: key, value: value)
            }.sorted { $0.id < $1.id }
            Task { @MainActor in
                self?.finish(id, value: sensors, hardware: HardwareMetrics(values: values), message: diagnostic)
            }
        }
    }

    private func resetConnection() {
        let old = connection
        connection = nil
        connectionID = nil
        old?.invalidate()
    }

    private func fail(_ id: UUID, message: String) {
        guard pending?.0 == id else { return }
        resetConnection()
        finish(id, value: [], message: message)
    }

    deinit {
        timeout?.cancel()
        connection?.invalidate()
    }

    private func finish(_ id: UUID, value: [TemperatureSensor], hardware: HardwareMetrics = HardwareMetrics(values: [:]), message: String) {
        guard let (pendingID, completion) = pending, pendingID == id else { return }
        pending = nil
        timeout?.cancel()
        timeout = nil
        completion(value, hardware, message)
    }
}
