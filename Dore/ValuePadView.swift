//
//  ValuePadView.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/3/25.
//

import SwiftUI

struct ValuePadView: View {
    @State private var speed = 0
    @State private var unit = "KB/S"
    var body: some View {
        
        VStack {
            Label("NetSpeed", systemImage: "speedometer")
            Spacer()
            HStack{
                Spacer()
                Text("↑")
                Spacer()
                Text("\(speed)")
                Text("\(unit)")
                Spacer()
            }
            HStack{
                Spacer()
                Text("↓")
                Spacer()
                Text("\(speed)")
                Text("\(unit)")
                Spacer()
            }
            Spacer()
        }
        .frame(width: 150, height: 100, alignment: .center)
    }
}


struct ValuePad_Previews: PreviewProvider {
    static var previews: some View {
        ValuePadView()
    }
}
