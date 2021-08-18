//
//  Util.swift
//  Dore
//
//  Created by WeIHa'S on 2021/8/17.
//

import Foundation

extension Double{
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
}
