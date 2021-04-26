//
//  SettingView.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct SettingView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem { Text("General") }
                .tag(0)
            ThemeSettingsView()
                .tabItem { Text("Theme") }
                .tag(1)
        }
        .frame(width: 400, height: 280, alignment: .center)
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}




struct GeneralSettingsView: View {
    
    @AppStorage("showPreview") private var startAuto = true
    @AppStorage("energySaving") private var EnergySaving = true
    @AppStorage("clickFunction") private var clickfunction : Bool = true
    @AppStorage("maxSetting") private var maxSetting : String  = "500"
    @AppStorage("minSetting") private var minSetting : String  = "50"
    @AppStorage("maxUnit") private var maxUnit : Bool = false
    @AppStorage("minUnit") private var minUint : Bool = false
    
    var body: some View {
        Form {
            GroupBox(label: Label("SpeedRange", systemImage: "speedometer")) {
                VStack{
                    HStack {
                        Label("Max", systemImage: "hare.fill")
                        TextField("Max", text: $maxSetting)
                        Picker("Unit", selection: $maxUnit) {
                            Text("KB/S").tag(false)
                            Text("MB/S").tag(true)
                        }
                    }
                    
                    HStack{
                        Label("Min", systemImage: "tortoise.fill")
                        TextField("Min", text: $minSetting)
                        Picker("Unit", selection: $minUint) {
                            Text("KB/S").tag(false)
                            Text("MB/S").tag(true)
                        }
                    }
                }
                .pickerStyle(PopUpButtonPickerStyle())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            }
            Spacer()
            GroupBox(label: Label("ClickFunc", systemImage: "cursorarrow.click")) {
                Picker(selection: $clickfunction, label: Text("Func")) {
                    Text("DarkMode").tag(true)
                    Text("SpeedPad").tag(false)
                }
                .disabled(true)
            }
            Spacer()
            
            HStack {
                GroupBox(label: Label("Automatic", systemImage: "person.circle")) {
                    HStack{
                        Toggle(isOn: $startAuto) {
                            Text("Self-start")
                        }
                        .disabled(true)
                        Spacer()
                        Spacer()
                        Toggle(isOn: $EnergySaving) {
                            Text("EnergySaving")
                        }
                        Spacer()
                    }
                }
                
            }
            Spacer()

        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}






struct ThemeSettingsView: View {
    
    @AppStorage("themeSetting") private var themeSetting : Bool = true
    
    
    var body: some View {
        VStack{
            Picker(selection: $themeSetting , label: Label("Theme", systemImage: "paintbrush")) {
                Text("Capsule").tag(true)
                Text("Circle").tag(false)
            }

            HStack{
                VStack {
                    MyProgress1(ViewModel: PreviewHandel)
                        .frame(width: 60, height: 120, alignment: .center)
                    Text("Capsule")
                }
                Spacer()
                VStack {
                    MyProgress2(ViewModel: PreviewHandel)
                        .frame(width: 80, height: 120, alignment: .center)
                    Text("Circle")
                }
            }
            
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}











