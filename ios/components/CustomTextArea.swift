//
//  CustomTextArea.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 24.06.2024.
//

import Foundation
import SwiftUI

struct CustomTextArea: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    @Binding var isFirstResponder: Bool
    
    var onEditingChanged: (Bool)->Void = { _ in }
    var keyboardType: UIKeyboardType = .default
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var calculatedHeight: CGFloat
        @Binding var isFirstResponder: Bool
        
        var didBecomeFirstResponder = false
        var onEditingChanged: (Bool)->Void = { _ in }
        
        init(text: Binding<String>, calculatedHeight: Binding<CGFloat>, onEditingChanged: @escaping (Bool)->Void = { _ in }, isFirstResponder: Binding<Bool>) {
            self._text = text
            self._calculatedHeight = calculatedHeight
            self.onEditingChanged = onEditingChanged
            self._isFirstResponder = isFirstResponder
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            text = textView.text ?? ""
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async{
                self.onEditingChanged(true)
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            DispatchQueue.main.async{
                self.onEditingChanged(false)
                self.isFirstResponder = false
                self.didBecomeFirstResponder = false
            }
        }
        
        func textViewDidChange(_ uiView: UITextView) {
            text = uiView.text
            CustomTextArea.recalculateHeight(view: uiView, result: $calculatedHeight)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return true
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<CustomTextArea>) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator

        textField.isEditable = true
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = false
        textField.backgroundColor = UIColor.clear
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }
    
    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<CustomTextArea>) {
        if uiView.text != self.text {
            uiView.text = self.text
        }
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
        CustomTextArea.recalculateHeight(view: uiView, result: $calculatedHeight)
    }
    
    func makeCoordinator() -> CustomTextArea.Coordinator {
        return Coordinator(text: $text, calculatedHeight: $calculatedHeight, onEditingChanged: self.onEditingChanged, isFirstResponder: self.$isFirstResponder)
    }
    
    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // !! must be called asynchronously
            }
        }
    }
}

struct CustomTextAreaFieldParent: View{
    @State private var value: String = "Ты в городе, а у меня дом в Алёшках. Пол беды что сами по себе Алёшки отшиб, дык е"
    @State private var isDisabled: Bool = false
    @State var responder: Bool = false
    @State private var height: CGFloat = 0
    
    var body: some View{
        ZStack{
            ScrollView{
                VStack(alignment: .leading){
                    Button("Toogle disabled [\(self.isDisabled ? "ON" : "OFF")]"){
                        self.isDisabled = !self.isDisabled
                    }
                    VStack{
                        CustomTextArea(
                            text: self.$value,
                            calculatedHeight: self.$height,
                            isFirstResponder: self.$responder
                        )
                        .frame(minHeight: self.height, maxHeight: self.height)
                        .outlined()
                            .disabled(self.isDisabled)
                        Text("Default field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                    
                    VStack{
                        CustomTextArea(
                            text: self.$value,
                            calculatedHeight: self.$height,
                            isFirstResponder: self.$responder
                        )
                        .frame(minHeight: self.height, maxHeight: self.height)
                        .outlined()
                            .disabled(self.isDisabled)
                        Text("Default field").font(.caption).frame(maxWidth: .infinity,alignment: .leading)
                    }
                }.padding()
            }
            
        }
    }
}

struct CustomTextAreaField_Previews: PreviewProvider {
    static var previews: some View {
        CustomTextAreaFieldParent()
    }
}
