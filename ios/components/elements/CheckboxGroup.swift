//
//  CheckboxGroup.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct CheckboxGroup: View {
    @Binding public var value: Array<String>
    @State public var options: [Option] = []
    @Environment(\.isEnabled) private var isEnabled
    
    func handleClick(_ option: Option){
        let index = value.firstIndex(of: option.id)
        if (index == nil){
            self.value.append(option.id)
        }else{
            self.value.remove(at: index!)
        }
    }
    
    var body: some View {
        VStack{
            ForEach(self.options, id: \.id){ option in
                let index = value.firstIndex(of: option.id)
                Button{
                    handleClick(option)
                } label: {
                    let checked = Binding<Bool>(get: {
                        return index != nil
                    }, set: { value in
                        handleClick(option)
                    })
                    
                    HStack(spacing:10){
                        Checkbox(checked: checked)
                            .disabled(!self.isEnabled)
                        Text(LocalizedStringKey(option.label))
                            .foregroundColor(self.isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(15)
        .overlay(
            RoundedRectangle(cornerRadius: Styles.cornerRadius)
                .stroke(Color.get(.BackgroundInput))
        )
    }
}

struct CheckboxGroupPreview: View {
    @State private var value: Array<String> = []
    
    var body: some View {
        VStack{
            CheckboxGroup(value: self.$value, options: [
                .init(id: "1", label: "Item A"),
                .init(id: "2", label: "Item B"),
                .init(id: "3", label: "Item C")
            ])
            CheckboxGroup(value: self.$value, options: [
                .init(id: "1", label: "Item A"),
                .init(id: "2", label: "Item B"),
                .init(id: "3", label: "Item C")
            ])
            .disabled(true)
        }
            .padding()
    }
}

struct CheckboxGroupPreview_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxGroupPreview()
    }
}
