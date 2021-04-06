//
//  Shell.swift
//  Doll
//
//  Created by WeIHa'S on 2020/11/25.
//

import Foundation


@discardableResult
func Shell(_ args: String...) ->String? {
    let task = Process()
    let pipe = Pipe()
    let error = Pipe()
    
  
//    print("shellwith",args)
    
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c"]+args
    task.standardOutput = pipe
    task.standardError = error
    task.launch()
    
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    task.waitUntilExit()
    
    
    if task.terminationStatus != 0 {
        return nil
    }
    
    return output
}
