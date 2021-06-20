//
//  GeneralSettingView.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import SwiftUI

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
