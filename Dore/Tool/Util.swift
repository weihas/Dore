//
//  Util.swift
//  Dore
//
//  Created by WeIHa'S on 2021/8/17.
//

import Foundation

extension Double{
    func Convert(_ Delta :Double) -> (Double,SpeedUnit) {
        var num :Double = Delta
        var unit = SpeedUnit.B
        var times = 0
        
        
        while num > 1024 {
            num = num/1024
            times += 1
        }
        switch times {
        case 0:
            unit = SpeedUnit.B
        case 1:
            unit = SpeedUnit.KB
        case 2:
            unit = SpeedUnit.MB
        case 3:
            unit = SpeedUnit.GB
        default:
            unit = SpeedUnit.B
        }
        return (num,unit)
        
    }
    
    func isContained(by range: Range<Double>) -> Bool {
        return range.contains(self)
    }
    
}

extension String {
    var splittedByWhitespace: [String] {
        guard let trimWhiteSpaceRegEx = try? NSRegularExpression(pattern: "/ +/g") else { return [] }
        let trimmed = trimWhiteSpaceRegEx.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: count),
            withTemplate: " "
        )
        return trimmed.split(separator: " ").map { String($0) }
    }
}
