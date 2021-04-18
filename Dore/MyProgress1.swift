//
//  MyProgress1.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct MyProgress1: View {
    @State private var placeholder = "hello"
    var body: some View {
        VStack{
            ZStack {
                Capsule()
                    .frame(alignment: .center)
                    .foregroundColor(Color.blue)
                    .opacity(0.3)
                Capsule()
                    .clipShape(RectBand(from: 0.3, to: 1))
                    .frame(alignment: .center)
                    .foregroundColor(Color.blue)
                
            }
            
        }
        .padding()
    }
}

struct MyProgress1_Previews: PreviewProvider {
    static var previews: some View {
        MyProgress1()
    }
}

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
