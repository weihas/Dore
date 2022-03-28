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
        VStack {
            HStack {
                    TabItem(name: "General", icon: "gear", tabNum: $tabNum, count: 0)
                    TabItem(name: "Theme", icon: "paintbrush", tabNum: $tabNum, count: 1)
            }
            .frame(width: 400, height: 30, alignment: .center)
            Divider()
            settingViewNow
        }
        .frame(width: 400, height: 280, alignment: .center)
    }
    
    var settingViewNow: some View {
        Group {
            switch tabNum{
            case 0: GeneralSettingsView()
                    .padding()
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            default:
                ThemeSettingsView()
                    .padding()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            }
        }
        .frame(width: 400, height: 215, alignment: .center)
    }
    

}


struct TabItem: View {
    public var name: String
    public var icon: String
    @Binding public var tabNum: Int
    @State public var isHover: Bool = false
    public var count: Int
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .padding(.vertical, 5)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray)
                        .opacity(tabNum == count ? 0.3: 0)
                )
            Text(name)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.bottom)
        }
        .onTapGesture {
            withAnimation {
                tabNum = count
            }
            
        }
    }
}



#if DEBUG
struct SettingView_Previews: PreviewProvider {

    static var previews: some View {
        SettingView()
    }
}

#endif




