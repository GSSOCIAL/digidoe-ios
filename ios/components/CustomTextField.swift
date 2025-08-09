//
//  CustomTextField.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 22.03.2024.
//

import Foundation
import SwiftUI

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    
    var onEditingChanged: (Bool)->Void = { _ in }
    var keyboardType: UIKeyboardType = .default
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isFirstResponder: Bool
        var didBecomeFirstResponder = false
        var onEditingChanged: (Bool)->Void = { _ in }

        init(text: Binding<String>, onEditingChanged: @escaping (Bool)->Void = { _ in }, isFirstResponder: Binding<Bool>) {
            _text = text
            self.onEditingChanged = onEditingChanged
            self._isFirstResponder = isFirstResponder
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField){
            DispatchQueue.main.async{
                self.onEditingChanged(true)
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField){
            DispatchQueue.main.async{
                self.onEditingChanged(false)
                self.isFirstResponder = false
                self.didBecomeFirstResponder = false
            }
        }
    }

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        //textField.setContentHuggingPriority(.required, for: .vertical)
        textField.keyboardType = self.keyboardType
        //textField.accessibilityScroll(.down)
        return textField
    }

    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(text: $text, onEditingChanged: self.onEditingChanged, isFirstResponder: self.$isFirstResponder)
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        uiView.text = text
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
    }
}
