//
//  PassCode.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.12.2023.
//

import Foundation
import SwiftUI
import AudioToolbox

struct PassCode: View {
    @Binding var passcode: String
    @State public var displayCode: Bool = false
    
    public var length: Int = 6
    public var onEnter: (String)->Void = { _ in }
    public var onAttempsLeft: ()->Void = { }
    
    @State public var checkPin: Bool = false
    @State var retry: Int = 0
    @State public var scheme: Color.CustomColorScheme = .auto
    
    var service: pin = pin()
    
    func vibrate(){
        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.error)
    }
    
    fileprivate func onKey(_ key: String){
        if self.passcode.count < self.length{
            self.passcode = [self.passcode,key].joined(separator:"")
        }
        if self.passcode.count >= self.length{
            //MARK: Call on enter method
            self.onEnter(self.passcode)
            
            if self.checkPin{
                if (self.service.verify(self.passcode)){
                    self.retry = 0
                }else{
                    self.vibrate()
                    self.retry += 1
                    if (self.retry > 3){
                        self.onAttempsLeft()
                    }
                }
            }
        }
    }
    
    fileprivate func cleanPassCode(){
        self.passcode = ""
    }
    
    fileprivate func removeChar(){
        self.passcode = String(self.passcode.dropLast())
    }
    
    var KeyBoard: some View{
        VStack(spacing:0){
            VStack(spacing:15){
                HStack(spacing:15){
                    Button("1"){
                        self.onKey("1")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    Button("2"){
                        self.onKey("2")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    Button("3"){
                        self.onKey("3")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                }
                HStack(spacing:10){
                    Button("4"){
                        self.onKey("4")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    
                    Button("5"){
                        self.onKey("5")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    
                    Button("6"){
                        self.onKey("6")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                }
                HStack(spacing:10){
                    Button("7"){
                        self.onKey("7")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    
                    Button("8"){
                        self.onKey("8")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    
                    Button("9"){
                        self.onKey("9")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                }
                HStack(spacing:10){
                    Button(" "){
                        
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    .disabled(true)
                    
                    Button("0"){
                        self.onKey("0")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                    
                    Button{
                        self.removeChar()
                    } label: {
                        Image("remove")
                    }
                    .buttonStyle(.passkey(scheme: self.scheme))
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment:.center){
            HStack(spacing:10){
                ForEach(0..<self.length){ n in
                    Circle()
                        .frame(maxWidth:12, maxHeight: 12)
                        .foregroundColor(self.passcode.count > n ? Whitelabel.Color(.Primary, scheme: self.scheme) : Color.get(.Ocean, scheme: self.scheme))
                        .background(self.passcode.count > n ? Whitelabel.Color(.Primary, scheme: self.scheme) : Color.get(.Ocean, scheme: self.scheme))
                        .clipShape(Circle())
                }
            }
            .frame(height: 12)
            if self.checkPin{
                Text(self.retry > 0 ? "Wrong pin! You have \(4 - self.retry) attempts" : "")
                    .padding(.bottom,10)
                    .font(.callout)
                    .foregroundColor(Color.get(.Danger))
            }
            self.KeyBoard
                .padding(.top,30)
        }
    }
}
