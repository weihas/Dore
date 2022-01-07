//
//  CircleView.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/18.
//

import SwiftUI

struct CircleView: View {
    @ObservedObject var vm : StatusItemShow
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                let thickness = geometry.size.height * 0.2
                CircleShape()
                    .stroke(Color.white ,style: StrokeStyle(lineWidth: thickness , lineCap: .round, lineJoin: .round))
                    .opacity(0.4)
                CircleShape(value: vm.nowPersent)
                    .stroke(Color.blue ,style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
                    .animation(.easeInOut)
                    .onAppear {
                        vm.startTimer()
                    }
            }
        }
    }
}

struct CircleShape: Shape {
    var value: Double = 1
    
    var animatableData: Double{
        get { value }
        set { value = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = Angle(degrees: 150)
        let end = Angle(degrees: 150 + 240 * value)

        var p = Path()
        p.addArc(center: center, radius: rect.midY, startAngle: start, endAngle: end, clockwise: false)
        return p
    }
}




//struct MyProgress2_Previews: PreviewProvider {
//    static var previews: some View {
//        let pre = ProgressViewControl()
//        CircleView(ViewModel: pre)
//    }
//}
