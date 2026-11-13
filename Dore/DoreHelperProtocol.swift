import Foundation

@objc(DoreHelperProtocol)
protocol DoreHelperProtocol {
    func readSensors(withReply reply: @escaping (Data?, String) -> Void)
    func readCPUTemperature(withReply reply: @escaping (NSNumber?, String) -> Void)
}
