//
//  GeneralSettingView.swift
//  Dore
//
//  Created by WeIHa'S on 2021/6/20.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var vm = SettingItems.defaults
    
    var body: some View {
        Form {
            GroupBox(label: Label("SpeedRange", systemImage: "speedometer")) {
                speedRangeView
            }
            
            Spacer()
            
            GroupBox(label: Label("ClickFunc", systemImage: "cursorarrow.click")) {
                clinkFuncView
            }
            
            Spacer()
            
            HStack {
                GroupBox(label: Label("Automatic", systemImage: "person.circle")) {
                    automaticView
                }
            }
            
            Spacer()
            
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
    
    private var speedRangeView: some View {
        VStack {
            HStack {
                Label("Max", systemImage: "hare.fill")
                TextField("Max", text: $vm.maxValue)
                Picker("Unit", selection: $vm.maxUnit) {
                    Text("B/S").tag(0)
                    Text("KB/S").tag(1)
                    Text("MB/S").tag(2)
                    Text("GB/S").tag(3)
                }
            }
            
            HStack{
                Label("Min", systemImage: "tortoise.fill")
                TextField("Min", text: $vm.minValue)
                Picker("Unit", selection: $vm.minUnit) {
                    Text("B/S").tag(0)
                    Text("KB/S").tag(1)
                    Text("MB/S").tag(2)
                    Text("GB/S").tag(3)
                }
            }
        }
        .pickerStyle(PopUpButtonPickerStyle())
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    private var clinkFuncView: some View {
        Picker(selection: $vm.clickFunc, label: Text("Func")) {
            Text("DarkMode").tag(true)
            Text("SpeedPad").tag(false)
        }
        .disabled(true)
    }
    
    private var automaticView: some View {
        HStack{
            Toggle(isOn: $vm.startAuto) {
                Text("Self-start")
            }
            .disabled(true)
            Spacer()
            Spacer()
            Toggle(isOn: $vm.energySaving) {
                Text("EnergySaving")
            }
            Spacer()
        }
    }
    
}
