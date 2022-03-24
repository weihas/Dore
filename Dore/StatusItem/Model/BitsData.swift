//
//  BitsData.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//
import Foundation

struct BitsDate {
    @PresentData var persent: Double
    
    private var nowData: Double = 0
    private var lastData: Double = 0
    var nowDelta: Double = 0
    private var lastDelta: Double = 0
    
    @discardableResult
    private func shellData(_ args: String...) -> Data? {
        let task = Process()
        let pipe = Pipe()
        let error = Pipe()
        
        
        //    print("shellwith",args)
        
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c"] + args
        task.standardOutput = pipe
        task.standardError = error
        task.launch()
        
        
        let data = try? pipe.fileHandleForReading.readToEnd()
        
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            return nil
        }
        
        return data
    }
    
    mutating func refreshData() {
        let args = "netstat -bI en0"    //Terminal command
        
        guard let data = shellData(args),
              let rows = String(data: data, encoding: String.Encoding.utf8)?.split(separator: "\n").map({String($0)}), rows.count > 1 else { return }
        let headers = rows[0].splittedByWhitespace
        let values = rows[1].splittedByWhitespace
        
        guard let raw = getValue(of: "ibytes", in: values, of: headers), let bytes = Double(raw) else {return}
        
        lastDelta = nowDelta
        
        nowDelta = bytes - nowData
        
        lastData = nowData
        
        nowData = bytes
        
        persent = nowDelta/SettingItems.defaults.maxBits
    }
    
    
    private func getValue(of column: String, in values: [String], of headers: [String]) -> String? {
        guard let index = headers.firstIndex(where: { $0.lowercased() == column }), values.indices.contains(index) else { return nil }
        return values[index]
    }
}



