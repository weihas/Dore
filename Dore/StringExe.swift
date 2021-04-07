//
//  StringExe.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/25.
//

import Foundation


public extension String {
    
    static func getValue(of column: String, in values: [String], of headers: [String]) -> String? {
        guard
            let index = headers.firstIndex(where: { $0.lowercased() == column }),
            values.indices.contains(index)
        else {
            return nil
        }
        return values[index]
    }
    
    var splittedByWhitespace: [String] {
        guard let trimWhiteSpaceRegEx = try? NSRegularExpression(pattern: "/ +/g") else {
            return []
        }
        let trimmed = trimWhiteSpaceRegEx.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: count),
            withTemplate: " "
        )
        return trimmed.split(separator: " ").map { String($0) }
    }
}
