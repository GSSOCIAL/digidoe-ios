//
//  Loader.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI

struct LoaderModifier: ViewModifier {
    @Binding var loading: Bool
    @State var style: LoaderStyle
    
    func body(content: Content) -> some View {
        return content.overlay(
            Group{
                self.style.background
                    .overlay(
                        Loader(size: self.style.size)
                    )
            }.opacity(self.loading ? 1 : 0)
        )
    }
}

struct LoaderStyle{
    var background: Color = Color("Background").opacity(0.8)
    var size: Loader.LoaderSize = .small
}

extension View{
    func loader(_ loading: Binding<Bool>, style: LoaderStyle = .init()) -> some View{
        modifier(LoaderModifier(loading: loading, style: style))
    }
}
