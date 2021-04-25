//
//  MyProgress1.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct MyProgress1: View {
    @ObservedObject var ViewModel : ButtonViewControl
    var body: some View {
        VStack{
            ZStack {
                Capsule()
                    .frame(alignment: .center)
                    .foregroundColor(Color.white)
                    .opacity(0.4)
                Capsule()
                    .clipShape(RectBand(from: CGFloat(ViewModel.NowPercent), to: 1))

                    .frame(alignment: .center)
                    .foregroundColor(Color.blue)
                    .animation(.default)

            }
        }
    }
}

//struct MyProgress1_Previews: PreviewProvider {
//    static var previews: some View {
//        MyProgress1(ViewModel: previewControl)
//    }
//}

struct RectBand: Shape {
    var from: CGFloat
    var to: CGFloat
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addRect(CGRect(
                x: rect.origin.x,
                y: rect.origin.y + (to-from) * rect.size.height,
                width: rect.size.width,
                height: from*rect.size.height
            ))
        }
    }
}
