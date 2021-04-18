//
//  SettingView.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct SettingView: View {
    @State private var selectedTab = 1
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem { Text("General") }
                .tag(0)
            ThemeSettingsView()
                .tabItem { Text("Theme") }
                .tag(1)
        }
        .frame(width: 400, height: 240, alignment: .center)
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}




struct ThemeSettingsView: View {
    
    @AppStorage("themeSetting") private var themeSetting = true
    
    
    var body: some View {
        VStack{
            Picker(selection: .constant(1), label: Label("Theme", systemImage: "paintbrush")) {
                Text("Capsule").tag(1)
                Text("Circle").tag(2)
            }
            HStack{
                
                VStack {
                    MyProgress1()
                        .frame(width: 80, height: 120, alignment: .center)
                    Text("Capsule")
                }
                Spacer()
                VStack {
                    MyProgress2()
                        .frame(width: 80, height: 120, alignment: .center)
                    Text("Circle")
                }
            }
            
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}
















struct GeneralSettingsView: View {

    @AppStorage("maxSetting") private var maxSetting = "500KB/s"
    @AppStorage("maxSetting") private var minSetting = "5KB/s"
    @AppStorage("showPreview") private var startAuto = true
    
    
    var body: some View {
        Form {
            GroupBox(label: Label("SpeedSet", systemImage: "speedometer")) {
                HStack {
                    Label("Max", systemImage: "hare.fill")
                    TextField("Placeholder", text: $maxSetting)
                    Label("Min", systemImage: "tortoise.fill")
                    TextField("Placeholder", text: $minSetting)
                }
            }
            Spacer()
            GroupBox(label: Label("ClickFunc", systemImage: "cursorarrow.click")) {
                Picker(selection: .constant(1), label: Text("Func")) {
                    Text("DarkMode").tag(1)
                    Text("SpeedPad").tag(2)
                }
            }
            Spacer()
            GroupBox(label: Label("Automatic", systemImage: "person.circle")) {
                Toggle(isOn: $startAuto) {
                    Text("Start when the system starts.")
                }
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}
