//
//  SpeedUnit.swift
//  Dore
//
//  Created by WeIHa'S on 2022/3/23.
//

import Foundation

enum SpeedUnit: Int {
    case B = 0
    case KB = 1
    case MB = 2
    case GB = 3
}

extension SpeedUnit {
    var name: String {
        switch self {
        case .B:
            return "B"
        case .KB:
            return "KB"
        case .MB:
            return "MB"
        case .GB:
            return "GB"
        }
    }
    
    var bitsValue: Double {
        switch self {
        case .B:
            return 1.0
        case .KB:
            return 1024.0
        case .MB:
            return 1024.0*1024.0
        case .GB:
            return 1024.0*1024.0*1024.0
        }
    }
    
    static func getUnit(val: Double) -> (Double,SpeedUnit) {
        var num = 0
        var value = val
        
        while value > 1000 {
            value /= 1024.0
            num += 1
        }
        
        return (value, SpeedUnit(rawValue: num) ?? .B)
    }
}
