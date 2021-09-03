//
//  GeneralSettingView.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewmodel: SettingItems
    
    var body: some View {
        Form {
            GroupBox(label: Label("SpeedRange", systemImage: "speedometer")) {
                VStack{
                    HStack {
                        Label("Max", systemImage: "hare.fill")
                        TextField("Max", text: $viewmodel.maxValue)
                        Picker("Unit", selection: $viewmodel.minUnit) {
                            Text("KB/S").tag(false)
                            Text("MB/S").tag(true)
                        }
                    }
                    
                    HStack{
                        Label("Min", systemImage: "tortoise.fill")
                        TextField("Min", text: $viewmodel.minValue)
                        Picker("Unit", selection: $viewmodel.minUnit) {
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
                Picker(selection: $viewmodel.clickFunc, label: Text("Func")) {
                    Text("DarkMode").tag(true)
                    Text("SpeedPad").tag(false)
                }
                .disabled(true)
            }
            Spacer()
            
            HStack {
                GroupBox(label: Label("Automatic", systemImage: "person.circle")) {
                    HStack{
                        Toggle(isOn: $viewmodel.startAuto) {
                            Text("Self-start")
                        }
                        .disabled(true)
                        Spacer()
                        Spacer()
                        Toggle(isOn: $viewmodel.energySaving) {
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
