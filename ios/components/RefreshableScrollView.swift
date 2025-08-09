//
//  RefreshableScrollView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.12.2023.
//

import Foundation
import SwiftUI

struct RefreshableScrollView<Content:View>: View{
    public var refresh: ()->Void = {}
    @Binding public var refreshing: Bool
    @Binding public var scrollOffset: Double
    
    let content: () -> Content
    
    private var loaderOffset: Double{
        if (self.refreshing){
            return 30
        }
        var offset = -50 + -self.scrollOffset
        if (offset > 30){
            offset = 30
        }else if(offset < -50){
            offset = -50
        }
        return offset
    }
    var body: some View{
        ScrollView{
            ZStack{
                content()
                    .offset(y: 0)
            }
            .background(GeometryReader {
                Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
            })
            .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                self.scrollOffset = position
            }
        }
        .coordinateSpace(name: "scroll")
        .onChange(of: scrollOffset){ _ in
            if (!self.refreshing && self.scrollOffset <= -100){
                self.refresh()
            }
        }
        .overlay(
            ZStack{
                Loader(size: .small)
            }
                .padding()
                .background(Color.get(.Text).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .offset(y: self.loaderOffset)
                .opacity(self.scrollOffset > -10 ? 0 : self.refreshing ? 1 : -self.scrollOffset / 100)
            ,alignment: .top
        )
    }
}

struct RefreshViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
