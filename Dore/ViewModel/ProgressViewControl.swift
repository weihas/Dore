//
//  ProgressViewControl.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/24.
//

import SwiftUI

class ProgressViewControl : ObservableObject  {
    @Published private var model: BitsDate
    
    init() {
        self.model = BitsDate()
    }
    
    
    // MARK: -Access to the model
    
    var nowPersent: Double {
        return model.nowPrecent
    }
    
    
    
    // MARK: -Intent(s)
    func refresh() {
        model.calculateSpeed()
    }
}
