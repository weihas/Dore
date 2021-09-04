//
//  BitsData.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//
import Foundation

struct BitsDate {
    private var value: BitsValue
    let maxBits: Double
    let minBits: Double
    @presentData() var nowPrecent: Double
    
    init(maxBits: Double, minBits: Double) {
        value = BitsValue()
        self.maxBits = maxBits
        self.minBits = minBits
        _nowPrecent.allowDelta = minBits/maxBits
    }
    
    mutating func calculateSpeed() {
        self.value.refreshData()
        if value.nowDelta - value.lastDelta > minBits/maxBits {
            nowPrecent =  value.nowDelta / maxBits
        }
    }
}

class BitsValue{
    var nowdata : Double = 0{
        didSet{
            lastdata = oldValue
            nowDelta = nowdata - oldValue
        }
    }
    
    var lastdata: Double = 0
    
    var lastDelta : Double = 0
    
    var nowDelta: Double = 0{
        didSet{
            lastDelta = oldValue
        }
    }
    
    func refreshData(){
        let args = "netstat -bI en0"    //Terminal command
        shellAsync(args) { result in
            guard let rows = result?.split(separator: "\n").map({ String($0) }),
                  rows.count > 1 else{ return }
            let headers = rows[0].splittedByWhitespace
            let values = rows[1].splittedByWhitespace
            
            guard let raw = String.getValue(of: "ibytes", in: values, of: headers), let bytes = Double(raw) else {return}
            DispatchQueue.main.sync {
                self.nowdata = bytes
            }
        }
    }
    
}
