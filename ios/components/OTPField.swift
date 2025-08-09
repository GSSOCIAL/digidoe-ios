//
//  OTPField.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.03.2024.
//

import Foundation
import SwiftUI

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),y: 0))
    }
}


struct OTPField: View{
    @Binding public var value: String
    @State public var keyboardType: UIKeyboardType = .numberPad
    @Binding public var isFailed: Bool
    
    public var length: Int = 6
    
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isKeyboardShowing: Bool
    
    @State private var shakeEffect: Int = 0
    
    @ViewBuilder
    func textBox(_ index: Int) -> some View{
        ZStack{
            if (value.count > index){
                let charIndex = self.value.index(self.value.startIndex, offsetBy: index)
                Text(String(self.value[charIndex]))
            }else{
                Text(" ")
            }
        }
        .font(.title3.weight(.medium))
        .foregroundColor(isEnabled ? Color.get(.Text) : Color.get(.DisabledText))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            //Is active field
            ZStack{
                let isActive = (self.isKeyboardShowing == true && ((self.value.count >= self.length && index == self.length - 1) || self.value.count == index))
                let hasValue = index+1 <= self.value.count
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEnabled ? (self.isFailed ? Color.get(.Danger) : (isActive ? Whitelabel.Color(.Primary) : hasValue ? Color.get(.LightGray).opacity(0.08) :  Color("BorderInactive"))) : Color.get(.Disabled))
                    .background(isEnabled ? (hasValue ? Color.get(.LightGray).opacity(0.08) : Color.clear) : Color.get(.Disabled))
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
        ).overlay(
            ZStack{
                //Add keyboard pipe
                if (self.isKeyboardShowing == true && (self.value.count == index)){
                    Rectangle()
                        .frame(width: 2, height: 20)
                        .foregroundColor(Color.get(.Text))
                }
            }
        )
        .modifier(Shake(animatableData: CGFloat(self.shakeEffect)))
    }
    
    var body: some View{
        ZStack{
            HStack(spacing: 16){
                ForEach(1...self.length, id: \.self){ i in
                    self.textBox(i-1)
                }
            }
            .background(
                TextField("",text: self.$value.limit(self.length))
                    .keyboardType(self.keyboardType)
                    .textContentType(.oneTimeCode)
                    //Hide field
                    .frame(width: 1, height: 1)
                    .opacity(0)
                    .blendMode(.screen)
                    .focused(self.$isKeyboardShowing)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                //Show keyboard on tap
                self.isKeyboardShowing = true
            }
            .onChange(of: self.value){ _ in
                if (self.value.count >= self.length){
                    self.isKeyboardShowing = false
                }
            }
            .onChange(of: self.isKeyboardShowing){ _ in
                if (self.isKeyboardShowing){
                    //Hide outside
                }
            }
            .onChange(of: self.isFailed){ _ in
                if (self.isFailed){
                    withAnimation(.default){
                        self.shakeEffect += 1;
                    }
                }
            }
            /*
            .toolbar{
                ToolbarItem(placement: .keyboard, content: {
                    Button{
                        self.isKeyboardShowing = false
                    } label: {
                        HStack{
                            Spacer()
                            Text("Done")
                            Spacer()
                        }
                    }
                })
            }
             */
        }
    }
}

fileprivate struct OTPFieldPreview: View{
    @State private var code: String = "01"
    @State private var isFailed: Bool = false
    
    var body: some View{
        OTPField(value: self.$code, isFailed: self.$isFailed)
        Button("Toggle"){
            self.isFailed = !self.isFailed
        }
    }
}

struct OTPField_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            OTPFieldPreview()
        }.padding()
    }
}
