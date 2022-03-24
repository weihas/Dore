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
    @AppStorage("themeSettingisCircle", store: .standard) var themeSettingisCircle: Bool = false
}

extension SettingItems{
    
    var maxBits: Double{
        get{
            let value = Double(maxValue) ?? 500
            return value * 1024 * (maxUnit ? 1024 : 1)
        }
    }
    
    var minBits: Double{
        get{
            let value = Double(minValue) ?? 5
            return value * 1024 * (minUnit ? 1024 : 1)
        }
    }
    
}




