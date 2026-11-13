import Foundation

// An embedded, per-application XPC service; no global Mach service or daemon.
final class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard connection.effectiveUserIdentifier == getuid() else { return false }
        connection.exportedInterface = NSXPCInterface(with: DoreHelperProtocol.self)
        // Energy deltas belong to a client; previews and the app must not consume
        // one another's sampling intervals.
        connection.exportedObject = DoreHelper()
        connection.resume()
        return true
    }
}

let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
