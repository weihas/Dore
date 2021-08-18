//
//  SettingView.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import SwiftUI

struct SettingView: View {
    @State var tabNum: Int = 0
    var body: some View {
        VStack{
            HStack {
                Spacer()
                Spacer()
                tabItem(name: "General",picture: "gear" ,count: 0)
                Spacer()
                tabItem(name: "Theme", picture: "paintbrush", count: 1)
                Spacer()
                Spacer()
            }
            .frame(width: 400, height: 30, alignment: .center)
            Divider()
            SettingViewNow()
        }
        .frame(width: 400, height: 280, alignment: .center)
    }
    
    @ViewBuilder
    func SettingViewNow() -> some View {
        Group{
            switch tabNum{
            case 0: GeneralSettingsView().padding()
            default:
                ThemeSettingsView().padding()
            }
        }
        .animation(.easeIn)
        .frame(width: 400, height: 215, alignment: .center)
    }
    
    
    @ViewBuilder
    func tabItem(name: String, picture: String, count: Int) -> some View {
        VStack{
            ZStack{
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray)
                    .frame(width: 40, height: 35, alignment: .center)
                    .opacity(tabNum == count ? 0.2 : 0)
                Image(systemName: picture)
                    .font(.title2)
            }
            Text(name)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.bottom)
        }
        .onTapGesture {
            withAnimation{
                tabNum = count
            }
        }
    }
    
    
    
}
struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}










