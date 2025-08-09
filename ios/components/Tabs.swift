//
//  Tabs.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.09.2023.
//

import SwiftUI

struct Tab: Hashable {
    var icon: Image?
    var title: String
    var id: Int
    @State var isAnimating: Bool = false
    
    @Environment(\.isEnabled) private var isEnabled
    
    var hashValue: Int {
        return id.hashValue
    }

    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var image: any View{
        if #available(iOS 17.0, *){
            return self.icon!.symbolEffect(.bounce.down, value: self.isAnimating)
        }else{
            return self.icon!
        }
    }
}

struct Tabs: View {
    var fixed = true
    var tabs: [Tab]
    @Binding var selectedTab: Int
    @Environment(\.isEnabled) private var isEnabled
    
    var style: Tabs.TabStyle = .initial
    
    enum TabStyle{
        case initial
        case selector
    }
    
    var selectedTabBackground: Color{
        if (!self.isEnabled){
            return Color.get(.DisabledText).opacity(0.3)
        }
        switch(self.style){
        case .initial:
            return Color.get(.Background)
        case .selector:
            return Whitelabel.Color(.Primary)
        }
    }
    var selectedTabText: Color{
        if (!self.isEnabled){
            return Color.get(.DisabledText)
        }
        switch(self.style){
        case .initial:
            return Whitelabel.Color(.Primary)
        case .selector:
            return Whitelabel.Color(.OnPrimary)
        }
    }
    
    var initialTabBackground: Color{
        if (!self.isEnabled){
            return Color.get(.Disabled)
        }
        switch(self.style){
        case .initial:
            return Color.clear
        case .selector:
            return Color.get(.Section)
        }
    }
    var initialTabText: Color{
        if (!self.isEnabled){
            return Color.get(.DisabledText)
        }
        switch(self.style){
        case .initial:
            return Color.get(.Text)
        case .selector:
            return Color.get(.MiddleGray)
        }
    }
    
    var TabBackground: Color{
        if (!self.isEnabled){
            return Color.get(.Disabled)
        }
        switch(self.style){
        case .initial:
            return Color.get(.Section)
        case .selector:
            return Color.clear
        }
    }
    
    var body: some View {
        GeometryReader{ tabsGeometry in
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        HStack(spacing: style == .initial ? 0 : 6) {
                            ForEach(0 ..< tabs.count, id: \.self) { row in
                                Button(action: {
                                    if #available(iOS 17.0, *){
                                        withAnimation(.bouncy, completionCriteria: .logicallyComplete, {
                                            if (self.isEnabled){
                                                selectedTab = row
                                                tabs[row].isAnimating = true
                                            }
                                        }, completion: {
                                            tabs[row].isAnimating = false
                                        })
                                    }else{
                                        withAnimation {
                                            if (self.isEnabled){
                                                selectedTab = row
                                            }
                                        }
                                    }
                                }, label: {
                                    HStack {
                                        tabs[row].icon
                                            .padding(.trailing,5)
                                        Text(tabs[row].title)
                                            .font(.subheadline.bold())
                                    }
                                    .accentColor(row == selectedTab ? selectedTabText : initialTabText)
                                    .foregroundColor(row == selectedTab ? selectedTabText : initialTabText)
                                    .padding(.vertical,10)
                                })
                                .frame(minWidth: (tabsGeometry.size.width - 8) / CGFloat(tabs.count))
                                .padding(.horizontal, style == .initial ? 0 : 12)
                                .padding(.vertical, style == .initial ? 0 : 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(row == selectedTab ? selectedTabBackground : initialTabBackground)
                                )
                            }
                        }
                        .padding(4)
                        .onChange(of: selectedTab) { target in
                            withAnimation {
                                proxy.scrollTo(target)
                            }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(TabBackground)
            )
            .onAppear(perform: {
                //UIScrollView.appearance().bounces = fixed ? false : true
            })
            .onDisappear(perform: {
                //UIScrollView.appearance().bounces = true
            })
        }.frame(maxHeight: 50)
    }
    
}

struct TabsPreview: View{
    @State private var selected: Int = 0
    
    var body: some View{
        NavigationView {
            VStack(spacing: 0) {
                if #available(iOS 17.0, *){
                    Image("briefcase")
                        .symbolEffect(.bounce, value: selected == 0)
                }
                Tabs(tabs: [
                    .init(icon: Image(systemName: "mail.stack"), title: "Individual", id: 0),
                    .init(icon: Image(systemName: "film.fill"), title: "Business", id: 1)
                ], selectedTab: self.$selected)
                //.disabled(true)
                TabView(selection: self.$selected,content: {
                    Text("1")
                        .tag(0)
                    Text("2")
                        .tag(1)
                })
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }.padding()
        }
    }
}
struct Tabs_Previews: PreviewProvider {
    static var previews: some View {
        TabsPreview()
    }
}
