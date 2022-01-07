//
//  SettingItems.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import Foundation
import SwiftUI

class SettingItems: ObservableObject {
    static var defaults = SettingItems()
    
    @AppStorage("startAuto", store: .standard) var startAuto: Bool = false
    @AppStorage("energySaving", store: .standard) var energySaving: Bool = true
    @AppStorage("clickFunc", store: .standard) var clickFunc: Bool = true
    @AppStorage("maxValue", store: .standard) var maxValue: String = "500"
    @AppStorage("maxUnit", store: .standard) var maxUnit: Bool = true
    @AppStorage("minValue", store: .standard) var minValue: String = "5"
    @AppStorage("minUnit", store: .standard) var minUnit: Bool = true
    @AppStorage("themeSetting", store: .standard) var themeSetting: Bool = false
}

extension SettingItems{
    
    static var maxBits: Double{
        get{
            let value = Double(SettingItems.defaults.maxValue) ?? 500
            return value * 1024 * (SettingItems.defaults.maxUnit ? 1024 : 1)
        }
    }
    
    static var minBits: Double{
        get{
            let value = Double(SettingItems.defaults.minValue) ?? 5
            return value * 1024 * (SettingItems.defaults.minUnit ? 1024 : 1)
        }
    }
    
}


enum speedUnit {
    case B
    case KB
    case MB
    case GB
}

