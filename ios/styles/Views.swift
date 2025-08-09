//
//  Views.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 24.05.2023.
//

import Foundation
import SwiftUI

struct FillModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .padding()
            .padding(.vertical,5)
            .background(Color("LightGray").opacity(0.08))
            .foregroundColor(Color("Text"))
            .cornerRadius(10)
    }
}

extension View{
    func filled() -> some View{
        modifier(FillModifier())
    }
}

struct OutlineModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .padding(10)
            .padding(.vertical,5)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                .stroke(Color("BackgroundInput"))
                .foregroundColor(Color.clear)
                .background(.clear)
            )
    }
}

extension View{
    func outlined() -> some View{
        modifier(OutlineModifier())
    }
}
