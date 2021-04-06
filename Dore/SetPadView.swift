//
//  SetPadView.swift
//  StingTest
//
//  Created by WeIHa'S on 2020/11/28.
//

import SwiftUI

struct SetPadView: View {
    
    enum Flavor: String, CaseIterable, Identifiable {
        case KB
        case MB
        case GB

        var id: String { self.rawValue }
    }
    
     
    
    @State public var ThemeisOn: Bool = false
    @State private var Bitseditor = "500"
    @State private var selectedUnits = Flavor.KB
    @State private var bgColor =
            Color(.sRGB, red: 0.2, green: 0.2, blue: 0.9)
    @State private var graycolor =
            Color(.sRGB, red: 0.75, green: 0.75, blue: 0.75)
    @State private var SystemColorOn: Bool = true
    @State private var BootisOn: Bool = false
    
    var body: some View {
        HStack(alignment: .center){
        VStack {
            GroupBox(label: Text("个性设置")) {
                HStack() {
                    Text("渲染式主题:    ")
                    Toggle(isOn: $ThemeisOn) {
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                .frame(width:150)
                
                HStack(){
                    Text("设置你的最大网速:")
                }
                .frame(width:150)
                HStack(){
                    if #available(OSX 11.0, *) {
                        TextField("1024", text: $Bitseditor)
                            .frame(width: 50.0)
                    } else {
                        // Fallback on earlier versions
                    }
                    
                    Picker(selection: $selectedUnits, label: Text("")) {
                        Text("KB").tag(Flavor.KB)
                        Text("MB").tag(Flavor.MB)
                        Text("GB").tag(Flavor.GB)
                    }
                    .frame(width: 60.0)
                }
                .frame(width:150)
                
                HStack(){
                    Text("自定义强调色:")
                    if #available(OSX 11.0, *) {
                        ColorPicker("", selection: $bgColor)
                            .frame(width:40,height:20)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                .frame(width:150)
                HStack(){
                    Toggle(isOn: $SystemColorOn) {
                        Text("跟随系统强调色")
                    }
                }
                .frame(width:150)
                HStack(){
                    Toggle(isOn: $BootisOn) {
                        Text("  跟随系统启动  ")
                    }
                }
                .frame(width:150)
            }
        }
            Spacer()
                .frame(width:60)
            
            VStack{
                Text("MAX:    \(Bitseditor)\(selectedUnits.rawValue)")
                    .font(.footnote)
                    .underline(true, color: Color.gray)
                    .multilineTextAlignment(.leading)
                    .frame(width:100, height: 15, alignment: .bottom)
                if(ThemeisOn){
                    LinearGradient(gradient: Gradient(colors: [graycolor,graycolor,graycolor,bgColor,bgColor]), startPoint: .topLeading, endPoint: .bottomLeading)
                        .frame(width: 70, height: 160,alignment: .top)
                        .cornerRadius(35)
                }else{
                    ZStack{
                        RoundedRectangle(cornerRadius: 35)
                            .fill(graycolor)
                            .frame(width: 70, height: 160,alignment: .bottom)
                        
                        VStack{
                            Spacer()
                                .frame(height: 90)
                            RoundedRectangle(cornerRadius: 35)
                                .fill(bgColor)
                                .frame(width: 70, height: 70, alignment: .bottomLeading)
                        }
                    }
                    
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SetPadView()
    }
}
