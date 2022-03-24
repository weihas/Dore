//
//  BitsData+PresentValue.swift
//  Dore
//
//  Created by WeIHa'S on 2021/9/4.
//

import Foundation

@propertyWrapper
struct PresentData {
    private var num: Double = 0
    private let min: Double = 0.005
    private let delta: Double = 0.05
    var wrappedValue: Double {
        get{
            return num
        }
        set{
            if newValue > 1 {
                num = 1
            }else if newValue < min{
                num = 0
            }else if abs(newValue - num) < delta{
                
            }else{
                num = newValue
            }
        }
    }
}
