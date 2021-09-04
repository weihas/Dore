//
//  BitsData+PresentValue.swift
//  Dore
//
//  Created by WeIHa'S on 2021/9/4.
//

import Foundation

@propertyWrapper
struct presentData {
    private var num: Double = 0
    var allowDelta: Double = 0.005
    var wrappedValue: Double {
        get{
            return num
        }
        set{
            if newValue > 1 {
                num = 1
            }else if newValue < allowDelta{
                num = 0
            }else{
                num = newValue
            }
        }
    }
}
