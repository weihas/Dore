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
        .padding()
        .frame(width: 400, height: 280, alignment: .center)
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}










