//
//  ThemeSettingView.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("themeSetting") private var themeSetting : Bool = false
    
    var body: some View {
        VStack{
            Picker(selection: $themeSetting , label: Label("Theme", systemImage: "paintbrush")) {
                Text("Capsule").tag(false)
                Text("Circle").tag(true)
            }
            HStack{
                Spacer()
                VStack{
                    capsule()
                        .frame(width: 50, height: 100, alignment: .center)
                    Text("Capsule")
                }
                Spacer()
                Spacer()
                VStack{
                    circle()
                        .frame(width: 100, height: 100, alignment: .center)
                    Text("Circle")
                }
                Spacer()
            }
            .padding()
        }
        .padding()
 
    }
    
    @ViewBuilder
    func capsule() -> some View {
        ZStack {
            Capsule()
                .frame(alignment: .center)
                .foregroundColor(.white)
                .opacity(0.4)
            Capsule()
                .clipShape(RectBand(value: 0.4))
                .animation(.easeOut)
                .frame(alignment: .center)
                .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    func circle() -> some View {
        GeometryReader { geometry in
            ZStack{
                let thickness = geometry.size.height * 0.2
                CircleShape()
                    .stroke(Color.white ,style: StrokeStyle(lineWidth: thickness , lineCap: .round, lineJoin: .round))
                    .opacity(0.4)
                CircleShape(value: 0.4)
                    .stroke(Color.blue ,style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
                    .animation(.easeInOut)
            }
            .padding()
        }
    }
    
    
}
