//
//  SettingItems.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import Foundation
import SwiftUI

class SettingItems {
    let defaults = UserDefaults.standard
    let settings = Settings()
    var maxBits: Double{
        get{
            SettingItems.maxSetting * 1024 * (maxUnit ? 1024 : 1)
        }
    }
    public var minBits: Double{
        get{
            SettingItems.minSetting * 1024 * (minUnit ? 1024 : 1)
        }
    }
   
    
    var startAuto: Bool{
        get{ defaults.bool(forKey: settings.startAuto)}
    }
    
    var energySaving: Bool{
        get{defaults.bool(forKey: settings.energySaving)}
    }
    var clickFunc: Bool{
        get{defaults.bool(forKey: settings.clickFunction)}
    }
    var maxSetting: String{
        get{defaults.string(forKey: settings.maxSetting) ?? "500"}
    }
    var maxUnit: Bool{
        get{defaults.bool(forKey: settings.maxUnit)}
    }
    
    var minSetting: String{
        get{defaults.string(forKey: settings.minSetting) ?? "50"}
    }
    
    var minUnit: Bool{
        get{defaults.bool(forKey: settings.minUnit)}
    }
    
    var themeSetting: Bool{
        get{defaults.bool(forKey: settings.themeSetting)}
    }
    
    static var maxSetting: Double{
        get{ Double(Int(UserDefaults.standard.string(forKey: "maxSetting") ?? "500") ?? 500)}
    }
    
    static var minSetting: Double{
        get{ return Double(Int(UserDefaults.standard.string(forKey: "minSetting") ?? "5") ?? 5) }
    }
    
    struct Settings {
        let startAuto = "startAuto"
        let energySaving = "energySaving"
        let clickFunction = "clickFunction"
        let maxSetting = "maxSetting"
        let maxUnit = "maxUnit"
        let minSetting = "minSetting"
        let minUnit = "minUnit"
        let themeSetting = "themeSetting"
    }
}



enum speedUnit {
    case B
    case KB
    case MB
    case GB
}

