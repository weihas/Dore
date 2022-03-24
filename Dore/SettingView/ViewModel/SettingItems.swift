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
    
    var maxBits: Double = 500*1024
    var minBits: Double = 5*1024
    
    init(){
        freshBits()
    }
    
    @AppStorage("startAuto", store: .standard) var startAuto: Bool = false
    @AppStorage("energySaving", store: .standard) var energySaving: Bool = true
    @AppStorage("clickFunc", store: .standard) var clickFunc: Bool = true
    @AppStorage("themeSettingisCircle", store: .standard) var themeSettingisCircle: Bool = false
    
    @AppStorage("maxValue", store: .standard) var maxValue: String = "2" {
        didSet {
            freshBits()
        }
    }
    @AppStorage("maxUnit", store: .standard) var maxUnit: Int = 2 {
        didSet {
            freshBits()
        }
    }
    @AppStorage("minValue", store: .standard) var minValue: String = "5" {
        didSet {
            freshBits()
        }
    }
    @AppStorage("minUnit", store: .standard) var minUnit: Int = 1 {
        didSet {
            freshBits()
        }
    }
   
    
    
    func freshBits() {
        guard let maxValue = Double(maxValue),
              let maxUnit = SpeedUnit(rawValue: maxUnit)?.bitsValue,
              let minValue = Double(minValue),
              let minUnit = SpeedUnit(rawValue: minUnit)?.bitsValue else { return }
        self.maxBits = maxValue*maxUnit
        self.minBits = minValue*minUnit
    }
}
