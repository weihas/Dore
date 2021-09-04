//
//  Shell.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/25.
//

import Foundation


@discardableResult
func shellData(_ args: String...) ->Data? {
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
    
    task.waitUntilExit()
    
    
    if task.terminationStatus != 0 {
        return nil
    }
    
    return data
}

func shellAsync(_ args: String, result: @escaping (String?)->Void){
    DispatchQueue.global().async {
        guard let data = shellData(args) else{
            result(nil)
            return
        }
        result(String(data: data, encoding: String.Encoding.utf8))
    }
}
