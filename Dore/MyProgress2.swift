//
//  MyProgress2.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/18.
//

import SwiftUI

struct MyProgress2: View {
    @State private var speed = 0.3
    var body: some View {
        VStack{
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(style: StrokeStyle(lineWidth: 15.0, lineCap: .round, lineJoin: .round))
                    .opacity(0.3)
                    .rotationEffect(Angle(degrees: 145.0))
                    .foregroundColor(Color.blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.speed, 0.7)))
                    .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.blue)
                    .rotationEffect(Angle(degrees: 145.0))
                    .animation(.linear)
            }
            
        }
        .padding()
    }
}

struct MyProgress2_Previews: PreviewProvider {
    static var previews: some View {
        MyProgress2()
    }
}
