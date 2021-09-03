//
//  SettingItems.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import Foundation
import SwiftUI

class SettingItems: ObservableObject {
    @SetStorage(key: "startAuto", default: false) var startAuto: Bool
    @SetStorage(key: "energySaving", default: true) var energySaving: Bool
    @SetStorage(key: "clickFunc", default: false) var clickFunc: Bool
    @SetStorage(key: "maxValue", default: "500") var maxValue: String
    @SetStorage(key: "maxUnit", default: false) var maxUnit: Bool
    @SetStorage(key: "minValue", default: "50") var minValue: String
    @SetStorage(key: "minUnit", default: false) var minUnit: Bool
    @SetStorage(key: "themeSetting", default: false) var themeSetting: Bool
}

extension SettingItems{
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
    
    static var maxSetting: Double{
        get{ Double(Int(UserDefaults.standard.string(forKey: "maxSetting") ?? "500") ?? 500)}
    }
    
    static var minSetting: Double{
        get{ return Double(Int(UserDefaults.standard.string(forKey: "minSetting") ?? "5") ?? 5) }
    }
    
}


enum speedUnit {
    case B
    case KB
    case MB
    case GB
}

