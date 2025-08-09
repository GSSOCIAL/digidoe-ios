//
//  RadioGroupView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct RadioGroup: View {
    @State public var items: Array<Option> = []
    @Binding public var value: String
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        VStack{
            ForEach(self.$items, id: \.id){ option in
                Button{
                    self.value = option.wrappedValue.id
                } label: {
                    let checked = Binding(get: {
                        return option.wrappedValue.id == value
                    }, set: { _ in
                        
                    })
                    HStack{
                        RadioItem(checked: checked, label: LocalizedStringKey(option.wrappedValue.label))
                            .disabled(!self.isEnabled)
                        Spacer()
                    }
                }
            }
        }
            .padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadius)
                    .stroke(Color("BackgroundInput"))
            )
    }
}

struct RadioGroupPreview: View{
    @State private var value: String = ""
    var body: some View{
        VStack{
            Header(back:{
                
            }, title: "")
            .padding(.bottom, 16)
            TitleView(title: LocalizedStringKey("In which currency would you prefer to open your account?"), description: LocalizedStringKey("You can open account in other currency after registration."))
                .padding(.horizontal, 16)
            HStack{
                RadioGroup(items: [
                    .init(id: "1", label: "GBP A/C"),
                    .init(id: "2", label: "Euro A/C"),
                    .init(id: "3", label: "Item C")
                ], value: self.$value)
                RadioGroup(items: [
                    .init(id: "1", label: "GBP A/C"),
                    .init(id: "2", label: "Euro A/C"),
                    .init(id: "3", label: "Item C")
                ], value: self.$value)
                .disabled(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
    }
}

struct RadioGroup_Previews: PreviewProvider {
    static var previews: some View {
        RadioGroupPreview()
    }
}
