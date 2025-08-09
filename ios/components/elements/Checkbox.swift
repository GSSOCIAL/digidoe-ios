//
//  Checkbox.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct Checkbox: View {
    @Binding public var checked: Bool
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button{
            self.checked = !self.checked
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 26, height: 26)
                .foregroundColor(self.isEnabled ? self.checked == true ? Whitelabel.Color(.Primary) : Color.clear : self.checked == true ? Color.get(.Disabled) : Color.clear)
                .background(self.isEnabled ? self.checked == true ? Whitelabel.Color(.Primary) : Color.clear : self.checked == true ? Color.get(.Disabled) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(self.isEnabled ? Whitelabel.Color(.Primary) : Color.get(.DisabledText))
                        ZStack{
                            RoundedRectangle(cornerRadius: 2)
                                .foregroundColor(self.isEnabled ? self.checked == true ? Color.white : Color.clear : self.checked == true ? Color.get(.DisabledText) : Color.clear)
                                .frame(maxWidth: 3, maxHeight: 8)
                                .rotationEffect(.degrees(-45))
                                .offset(x:-3, y: 1)
                            RoundedRectangle(cornerRadius: 2)
                                .foregroundColor(self.isEnabled ? self.checked == true ? Color.white : Color.clear : self.checked == true ? Color.get(.DisabledText) : Color.clear)
                                .frame(maxWidth: 3, maxHeight: 12)
                                .rotationEffect(.degrees(45))
                                .offset(x:2)
                        }
                    }
                )
        }
    }
}

struct CheckboxPreview: View {
    @State private var checked: Bool = false
    var body: some View {
        HStack{
            Checkbox(checked: self.$checked)
                .padding()
            Checkbox(checked: self.$checked)
                .disabled(true)
                .padding()
            Checkbox(checked: .constant(true))
                .padding()
            Checkbox(checked: .constant(true))
                .disabled(true)
                .padding()
        }
    }
}

struct CheckboxPreview_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxPreview()
    }
}
