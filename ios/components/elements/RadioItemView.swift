//
//  RadioItemView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct RadioItem: View {
    @Binding var checked: Bool
    @State public var label: LocalizedStringKey
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        HStack(alignment: .center){
            ZStack{
                Circle()
                    .foregroundColor(self.isEnabled ? Color.white : Color.get(.DisabledText))
                    .frame(width: 6, height: 6)
                    .zIndex(2)
                    .opacity(self.checked ? 1 : 0)
                Circle()
                    .foregroundColor(self.isEnabled ? Whitelabel.Color(.Primary) : Color.get(.Disabled))
                    .zIndex(1)
                    .scaleEffect(self.checked ? 1 : 0)
            }
            .frame(width: 18, height: 18)
            .overlay(
                Circle()
                    .stroke(self.isEnabled ? Color.get(.Ocean) : Color.get(.DisabledText))
                    .scaleEffect(self.checked ? 0 : 1)
            )
            .padding(.trailing,5)
            VStack(alignment:.leading,spacing:0){
                Text(self.label)
                    .font(.subheadline)
                    .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
            }
            .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}

struct RadioItem_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            HStack{
                RadioItem(checked: .constant(true), label: "Option")
                RadioItem(checked: .constant(false), label: "Option")
            }
            HStack{
                RadioItem(checked: .constant(true), label: "Option").disabled(true)
                RadioItem(checked: .constant(false), label: "Option").disabled(true)
            }
        }.padding()
    }
}

