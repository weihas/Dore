//
//  BitsData.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

struct BitsDate {
    private var value: BitsValue
    let settings = SettingItems()
    var nowPrecent: Double = 0
    
    init() {
        value = BitsValue()
    }
    
    mutating func calculateSpeed() {
        let nowdate = value.nowdata
        value.lastDelta = value.nowDelta
        value.nowDelta = nowdate - value.lastdata
        let precent =  value.nowDelta / settings.maxBits
        if precent > 1 {
            nowPrecent = 1
        }else if precent < settings.minBits / settings.maxBits {
            nowPrecent = 0
        }else{
            nowPrecent = precent
        }
        value.lastdata = nowdate
    }
}

struct BitsValue{
    var nowdata : Double {
        get{
            let args = "netstat -bI en0"    //Terminal command
            if let rows = Shell(args)?.split(separator: "\n").map({ String($0) }),
               rows.count > 1 {
                let headers = rows[0].splittedByWhitespace
                let values = rows[1].splittedByWhitespace
                if let raw = String.getValue(of: "ibytes", in: values, of: headers), let bytes = UInt64(raw) {
                    return Double(bytes)
                }
            }
            return 0
        }
    }
    var lastdata: Double = 0
    
    var lastDelta : Double = 0
    
    var nowDelta: Double = 0
}
