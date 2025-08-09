//
//  Header.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.09.2023.
//

import Foundation
import SwiftUI

struct Header<Body>: View where Body: View{
    public var back: ()->Void = {}
    @State public var title: LocalizedStringKey
    @State public var subtitle: LocalizedStringKey? = nil
    public var actions: (() -> Body)?
    var scheme: Color.CustomColorScheme = .auto
    
    public init(back: @escaping ()->Void, title: String, subtitle: String? = nil, scheme: Color.CustomColorScheme = .auto, @ViewBuilder actions: @escaping ()->Body){
        self.back = back
        self.title = LocalizedStringKey(title)
        self.subtitle = LocalizedStringKey(subtitle ?? "")
        self.actions = actions
        self.scheme = scheme
    }
    
    @MainActor public var body: some View{
        HStack{
            Button{
                self.back()
            } label:{
                ZStack{
                    Image("arrow-left")
                        .foregroundColor(Color.get(.PaleBlack, scheme: self.scheme))
                }
                .frame(width: 24, height: 24)
            }
            Spacer()
            ZStack{
                if (self.actions != nil){
                    self.actions!()
                }
            }
        }
        .padding(.horizontal,16)
        .padding(.vertical, 12)
        .overlay(
            VStack{
                Text(self.title)
                    .foregroundColor(Color.get(.Text, scheme: self.scheme))
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
            }
        )
    }
}

extension Header where Body == Text{
    init(back: @escaping ()->Void, title: String, subtitle: String? = nil, scheme: Color.CustomColorScheme = .auto, actions: String? = nil){
        self.back = back
        self.title = LocalizedStringKey(title)
        self.subtitle = LocalizedStringKey(subtitle ?? "")
        self.actions = nil
        self.scheme = scheme
    }
    
    init(back: @escaping ()->Void, title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, scheme: Color.CustomColorScheme = .auto, actions: String? = nil){
        self.back = back
        self.title = title
        self.subtitle = subtitle
        self.actions = nil
        self.scheme = scheme
    }
}
