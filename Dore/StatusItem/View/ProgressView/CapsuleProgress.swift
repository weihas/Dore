//
//  CapsuleProgress.swift
//  Dore
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct CapsuleProgress: View {
    @ObservedObject var vm : StatusItemShow
    var body: some View {
        
        Capsule()
            .clipShape(RectBand(value: vm.nowPersent))
            .animation(.easeOut)
            .aspectRatio(0.45, contentMode: .fit)
            .foregroundColor(Color.primary)
            .background(
                Capsule()
                    .foregroundColor(.white)
                    .opacity(0.4))
            .onAppear {
                vm.startTimer()
            }
    }
    
    

}


struct RectBand: Shape {
    var value: Double
    
    var animatableData: Double {
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
