//
//  CapsuleProgress.swift
//  Dore
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct CapsuleProgress: View {
    @ObservedObject var ViewModel : StatusBarItem
    var body: some View {
        ZStack {
            Capsule()
                .frame(alignment: .center)
                .foregroundColor(.white)
                .opacity(0.4)
            Capsule()
                .clipShape(RectBand(value: CGFloat(ViewModel.nowPersent)))
                .animation(.easeOut)
                .foregroundColor(.blue)
        }
    }
}


struct RectBand: Shape {
    var value: CGFloat
    
    var animatableData: CGFloat{
        get { value }
        set { value = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: rect.maxY * (1-value),
                   width: rect.maxX, height: rect.maxY * value))
    }
}


//struct MyProgress1_Previews: PreviewProvider {
//
//    static var previews: some View {
//
//        let bu = ProgressViewControl()
//        CapsuleProgress(ViewModel: bu)
//    }
//}
