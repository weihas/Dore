//
//  ButtonViewControl.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/24.
//

import Foundation

class ButtonViewControl : ObservableObject  {
    @Published var NowPercent :Double  =  0.1
    
    init() {
    }
    
    func Refresh(minValue: Double , maxValue :Double , NowValue :Double) {
        self.NowPercent = min( NowValue/maxValue, 1)
    }
}

let PreviewHandel = ButtonViewControl()

