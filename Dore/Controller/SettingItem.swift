//
//  SettingItem.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import Foundation
import SwiftUI

struct SettingItem {
    var maxBits: Double{
        get{
            maxSetting * 1024 * (maxUnit ? 1024 : 1)
        }
    }
    var minBits: Double{
        get{
            minSetting * 1024 * (minUnit ? 1024 : 1)
        }
    }
    

    
    
    

    func Convert(_ Delta :Double) -> (Double,speedUnit) {
        var num :Double = Delta
        var unit = speedUnit.B
        var times = 0
        
        
        while num > 1024 {
            num = num/1024
            times += 1
        }
        switch times {
        case 0:
            unit = speedUnit.B
        case 1:
            unit = speedUnit.KB
        case 2:
            unit = speedUnit.MB
        case 3:
            unit = speedUnit.GB
        default:
            unit = speedUnit.B
        }
        return (num,unit)
        
    }
    
    
    var maxSetting: Double{
        get{ return Double(Int(UserDefaults.standard.string(forKey: "maxSetting") ?? "500") ?? 500)}
    }
    var minSetting: Double{
        get{ return Double(Int(UserDefaults.standard.string(forKey: "minSetting") ?? "5") ?? 5) }
    }
    var maxUnit: Bool{
        get{UserDefaults.standard.bool(forKey: "maxUnit") }
    }
    var minUnit: Bool{
        get{UserDefaults.standard.bool(forKey: "minUnit") }
    }
    
    static var clickfunc: Bool{
        get{ UserDefaults.standard.bool(forKey: "clickFunction")}
    }
    static var energySaving: Bool{
        get{ UserDefaults.standard.bool(forKey: "energySaving") }
    }
    
    static var themeSetting: Bool{
        get{UserDefaults.standard.bool(forKey: "themeSetting") }
    }
}


enum speedUnit {
    case B
    case KB
    case MB
    case GB
}

