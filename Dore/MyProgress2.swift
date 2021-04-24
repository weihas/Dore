//
//  MyProgress2.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/18.
//

import SwiftUI

struct MyProgress2: View {
    @ObservedObject var ViewModel : ButtonViewControl
    var body: some View {
        VStack{
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .opacity(0.6)
                    .rotationEffect(Angle(degrees: 145.0))
                    .foregroundColor(Color.white)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.ViewModel.NowPercent*0.7, 0.7)))
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.blue)
                    .rotationEffect(Angle(degrees: 145.0))
            }
            
        }
    }
}

struct MyProgress2_Previews: PreviewProvider {
    static var previews: some View {
        MyProgress2(ViewModel: PreviewHandel)
    }
}
