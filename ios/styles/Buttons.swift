//
//  Buttons.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 27.12.2022.
//

import Foundation
import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return VStack{
            if (self.image != nil && self.image!.isEmpty == false){
                ZStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                        .frame(width: 24)
                }
                    .frame(width:24,height:24)
            }
            configuration.label
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.get(.Text, scheme: self.scheme))
        }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.get(.LightGray, scheme: self.scheme).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PassKeyButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var scheme: Color.CustomColorScheme = .auto
    
    init(scheme: Color.CustomColorScheme = .auto) {
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return ZStack{
            configuration.label
        }
            .padding()
            .frame(width:75, height: 75)
            .background(self.isEnabled ? (configuration.isPressed ? Color.get(.LightGray, scheme: self.scheme).opacity(0.4) : Color.get(.LightGray, scheme: self.scheme).opacity(0.08)) : Color.get(.LightGray, scheme: self.scheme).opacity(0.08))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.Text, scheme: self.scheme) : Color.get(.Text, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.title.weight(.regular))
            .clipShape(Circle())
    }
}

struct NextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var outlined: Bool = false
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Whitelabel.ColorScheme = .auto
    
    init(image: String? = nil, outlined: Bool = false, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.outlined = outlined
        self.scheme = scheme
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 16 + (self.image != nil ? 48 : 0))
            .padding(.vertical,18)
            .multilineTextAlignment(.leading)
            .frame(maxWidth:.infinity, minHeight: 34, alignment: .leading)
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.MiddleGray, scheme: self.scheme) : Color.get(.Text, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.body.bold())
            .background(Color.get(.Background, scheme: self.scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                ZStack{
                    Image("arrow-next")
                        .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                }
                    .frame(width: 24, height: 24)
                    .padding(.trailing,16)
                ,alignment: .trailing
            )
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Whitelabel.Color(.Primary, scheme: self.customScheme))
                        }
                            .frame(width:32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                , alignment: .leading
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(self.outlined ? Color.get(.BackgroundInput, scheme: self.scheme) : Color.clear)
                    .foregroundColor(Color.clear)
                    .background(.clear)
            )
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

struct RadioButtonSelector: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Whitelabel.ColorScheme = .auto
    @Binding private var checked: Bool
    
    init(checked: Binding<Bool>, image: String? = nil, outlined: Bool = false, scheme: Color.CustomColorScheme = .auto) {
        self.scheme = scheme
        self._checked = checked
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return 
        HStack(spacing:10){
            ZStack{
                Circle()
                    .foregroundColor(self.isEnabled ? Whitelabel.Color(.OnPrimary) : Color.get(.Disabled))
                    .frame(maxWidth: 6, maxHeight: 6)
                    .zIndex(2)
                    .opacity(self.checked ? 1 : 0)
                Circle()
                    .foregroundColor(self.isEnabled ? Whitelabel.Color(.Primary, scheme: self.customScheme) : Color.get(.DisabledText))
                    .zIndex(1)
                    .scaleEffect(self.checked ? 1 : 0)
            }
            .frame(maxWidth: 18, maxHeight: 18)
            .overlay(
                Circle()
                    .stroke(self.isEnabled ? Color("Ocean") : Color.get(.DisabledText, scheme: self.scheme))
                    .scaleEffect(self.checked ? 0 : 1)
            )
            configuration
                .label
                .font(.subheadline)
                .foregroundColor(self.isEnabled ? Color.get(.Text, scheme: self.scheme) : Color.get(.DisabledText, scheme: self.scheme))
        }
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(self.isEnabled ? Color.get(.BackgroundInput, scheme: self.scheme) : Color.get(.Disabled, scheme: self.scheme))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .foregroundColor(self.isEnabled ? Color.get(.Background, scheme: self.scheme) : Color.get(.Disabled, scheme: self.scheme))
                )
        )
        .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

struct PlainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Whitelabel.ColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 16 + (self.image != nil ? 48 : 0))
            .padding(.vertical,18)
            .multilineTextAlignment(.leading)
            .frame(maxWidth:.infinity, minHeight: 34, alignment: .leading)
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.MiddleGray, scheme: self.scheme) : Color.get(.Text, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.body.bold())
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Whitelabel.Color(.Primary, scheme: self.customScheme))
                        }
                            .frame(width:32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                , alignment: .leading
            )
    }
}

struct LinkButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Whitelabel.ColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 16 + (self.image != nil ? 48 : 0))
            .padding(.vertical,18)
            .multilineTextAlignment(.leading)
            .frame(minHeight: 34, alignment: .leading)
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.Primary, scheme: self.customScheme).opacity(0.7) : Whitelabel.Color(.Primary, scheme: self.customScheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.body.weight(.medium))
            .background(Color.get(.Background))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Whitelabel.Color(.Primary, scheme: self.customScheme))
                                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                        }
                            .frame(width:32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                , alignment: .leading
            )
    }
}

struct DangerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 16 + (self.image != nil ? 48 : 0))
            .padding(.vertical,18)
            .multilineTextAlignment(.leading)
            .frame(maxWidth:.infinity, minHeight: 34, alignment: .leading)
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.Danger, scheme: self.scheme) : Color.get(.Danger, scheme: self.scheme).opacity(0.8)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.body.bold())
            .background(Color.get(.Background, scheme: self.scheme))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.get(.Danger, scheme: self.scheme))
                        }
                            .frame(width:32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                , alignment: .leading
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Whitelabel.ColorScheme = .auto
    private var customScheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        if (scheme == .auto){
            self.scheme = .auto
        }else if(scheme == .light){
            self.scheme = .light
        }else{
            self.scheme = .dark
        }
        self.customScheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 12 + (self.image != nil ? 24 : 0))
            .padding(.vertical,12)
            .padding(.trailing, 12)
            .multilineTextAlignment(.center)
            .frame(minHeight: 34)
            .background(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.Secondary).opacity(0.8) : Whitelabel.Color(.Secondary)) : Color.get(.Disabled, scheme: self.customScheme))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.OnSecondary, scheme: self.scheme).opacity(0.6) : Whitelabel.Color(.OnSecondary, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.customScheme))
            .font(.subheadline.weight(.medium))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(self.isEnabled ? Whitelabel.Color(.OnSecondary, scheme: self.scheme) : Color.get(.DisabledText, scheme: self.customScheme))
                        }
                            .frame(width:16, height: 16)
                            .padding(.leading, 12)
                    }
                }
                , alignment: .leading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 9)
            )
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 12 + (self.image != nil ? 24 : 0))
            .padding(.vertical,12)
            .padding(.trailing, 12)
            .multilineTextAlignment(.center)
            .frame(minHeight: 34)
            .background(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.Quaternary).opacity(0.8) : Whitelabel.Color(.Quaternary)) : Color.get(.Disabled, scheme: self.scheme))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.OnQuaternary, scheme: self.scheme).opacity(0.6) : Whitelabel.Color(.OnQuaternary, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.subheadline.weight(.medium))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(self.isEnabled ? Whitelabel.Color(.OnQuaternary, scheme: self.scheme) : Color.get(.DisabledText, scheme: self.scheme))
                        }
                            .frame(width:16, height: 16)
                            .padding(.leading, 12)
                    }
                }
                , alignment: .leading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 9)
            )
    }
}

struct SecondaryGrayButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 12 + (self.image != nil ? 24 : 0))
            .padding(.vertical,12)
            .padding(.trailing, 12)
            .multilineTextAlignment(.center)
            .frame(minHeight: 34)
            .background(self.isEnabled ? (configuration.isPressed ? Color.get(.LightGray).opacity(0.8) : Color.get(.LightGray)) : Color.get(.Disabled, scheme: self.scheme))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.Background, scheme: self.scheme).opacity(0.6) : Color.get(.Background, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.subheadline.weight(.medium))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(self.isEnabled ? Color.get(.Background, scheme: self.scheme) : Color.get(.DisabledText, scheme: self.scheme))
                        }
                            .frame(width:16, height: 16)
                            .padding(.leading, 12)
                    }
                }
                , alignment: .leading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 9)
            )
    }
}

struct SecondaryDangerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 12 + (self.image != nil ? 24 : 0))
            .padding(.vertical,12)
            .padding(.trailing, 12)
            .multilineTextAlignment(.center)
            .frame(minHeight: 34)
            .background(self.isEnabled ? (configuration.isPressed ? Color.get(.Danger).opacity(0.08) : Color.get(.Danger).opacity(0.14)) : Color.get(.Disabled))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.Danger).opacity(0.6) : Color.get(.Danger)) : Color.get(.DisabledText))
            .font(.subheadline.weight(.medium))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(self.isEnabled ? Color.get(.Danger): Color.get(.DisabledText))
                        }
                            .frame(width:16, height: 16)
                            .padding(.leading, 12)
                    }
                }
                , alignment: .leading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 9)
            )
    }
}

struct SecondaryActiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 12 + (self.image != nil ? 24 : 0))
            .padding(.vertical,12)
            .padding(.trailing, 12)
            .multilineTextAlignment(.center)
            .frame(minHeight: 34)
            .background(self.isEnabled ? (configuration.isPressed ? Color.get(.Active).opacity(0.08) : Color.get(.Active).opacity(0.14)) : Color.get(.Disabled))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.Active).opacity(0.6) : Color.get(.Active)) : Color.get(.DisabledText))
            .font(.subheadline.weight(.medium))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(self.isEnabled ? Color.get(.Active) : Color.get(.DisabledText))
                        }
                            .frame(width:16, height: 16)
                            .padding(.leading, 12)
                    }
                }
                , alignment: .leading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 9)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Whitelabel.ColorScheme = .auto
    private var customScheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        if (scheme == .auto){
            self.scheme = .auto
        }else if(scheme == .light){
            self.scheme = .light
        }else{
            self.scheme = .dark
        }
        self.customScheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .padding(.leading, 12 + (self.image != nil ? 24 : 0))
            .padding(.vertical,12)
            .padding(.trailing, 12)
            .multilineTextAlignment(.center)
            .frame(minHeight: 34)
            .background(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.Primary).opacity(0.8) : Whitelabel.Color(.Primary)) : Color("Disabled"))
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Whitelabel.Color(.OnPrimary).opacity(0.6) : Whitelabel.Color(.OnPrimary)) : Color.get(.DisabledText))
            .font(.subheadline.weight(.medium))
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(self.isEnabled ? Whitelabel.Color(.OnPrimary) : Color.get(.DisabledText))
                        }
                            .frame(width:16, height: 16)
                            .padding(.leading, 12)
                    }
                }
                , alignment: .leading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 9)
            )
    }
}

struct SecondaryRoundedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil,scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return VStack{
            ZStack{
                if (self.image != nil){
                    ZStack{
                        Image(self.image!)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Whitelabel.Color(.Primary))
                            .opacity(configuration.isPressed ? 0.6 : 1)
                    }
                        .frame(width: 28, height: 28)
                }
            }
                .frame(width: 52, height: 52)
                .background(Whitelabel.Color(.Secondary))
                .clipShape(Circle())
            configuration
                .label
                .font(.caption.weight(.semibold))
                .foregroundColor(configuration.isPressed ? Color("MiddleGray").opacity(0.6) : Color("MiddleGray"))
        }
    }
}

struct SecondaryNextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Color.CustomColorScheme = .auto
    private var size: ButtonSize = .normal
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto, size: ButtonSize = .normal) {
        self.image = image
        self.scheme = scheme
        self.size = size
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration
            .label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .padding(.leading, 16 + (self.image != nil ? 48 : 0))
            .padding(.vertical, self.size == .normal ? 18 : 8)
            .multilineTextAlignment(.leading)
            .frame(maxWidth:.infinity, minHeight: 34, alignment: .leading)
            .foregroundColor(self.isEnabled ? (configuration.isPressed ? Color.get(.Text, scheme: self.scheme).opacity(0.8) : Color.get(.Text, scheme: self.scheme)) : Color.get(.DisabledText, scheme: self.scheme))
            .font(.body.bold())
            .overlay(
                ZStack{
                    Image("arrow-next")
                        .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                }
                    .frame(width: 24, height: 24)
                    .padding(.trailing,16)
                ,alignment: .trailing
            )
            .overlay(
                ZStack{
                    if (self.image != nil){
                        ZStack{
                            Image(self.image!)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                        }
                            .frame(width:32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                , alignment: .leading
            )
            .padding(.vertical, 6)
            .background(self.isEnabled ? ( configuration.isPressed ? Color.get(.Section, scheme: self.scheme).opacity(0.6) : Color.get(.Section, scheme: self.scheme) ) : Color.get(.Disabled))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            //.padding(.horizontal, 16)
    }
}

//Idk
struct DetailedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var description: String? = nil
    @Binding private var checked: Bool
    private var scheme: Color.CustomColorScheme = .auto
    private var customScheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, description: String? = nil, checked: Binding<Bool> = .constant(false), scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.description = description
        self._checked = checked
        self.scheme = scheme
        if (scheme == .light){
            self.customScheme = .light
        }else if(scheme == .dark){
            self.customScheme = .dark
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack(alignment: .top){
            if (self.image != nil && !self.image!.isEmpty){
                ZStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Whitelabel.Color(.OnPrimary))
                        .frame(width: 24)
                }
                    .frame(width:48,height:48)
                    .background(Whitelabel.Color(.OnPrimary).opacity(0.2))
                    .cornerRadius(12)
                    .scaleEffect(configuration.isPressed ? 0.9 : 1)
            }
            VStack(alignment:.leading,spacing:2){
                Group{
                    if(self.image != nil && self.image?.isEmpty == false){
                        configuration
                            .label
                            .padding(.top,6)
                            .frame(maxWidth: .infinity, alignment:.leading)
                            .multilineTextAlignment(.leading)
                    }else{
                        configuration
                            .label
                            .frame(maxWidth: .infinity, alignment:.leading)
                            .multilineTextAlignment(.leading)
                    }
                }
                    .font(.subheadline.bold())
                    .foregroundColor(Color.get(.Text, scheme: self.scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Group{
                    if (self.description != nil && !self.description!.isEmpty){
                        Text(LocalizedStringKey(self.description!))
                            .frame(maxWidth: .infinity, alignment:.leading)
                            .multilineTextAlignment(.leading)
                    }
                }
                    .font(.caption)
                    .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
            }
            .frame(maxWidth: .infinity)
            if (self.checked == true){
                HStack(alignment: .center){
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color("Active"))
                        .overlay(
                            ZStack{
                                RoundedRectangle(cornerRadius: 2)
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: 2, maxHeight: 6)
                                    .rotationEffect(.degrees(-45))
                                    .offset(x:-3)
                                RoundedRectangle(cornerRadius: 2)
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: 2, maxHeight: 8)
                                    .rotationEffect(.degrees(45))
                                    .offset(x:2)
                            }
                        )
                }
                .padding(.top,15)
            }
        }
            .padding(10)
            .background(Color.get(.Background, scheme: self.scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.get(.BackgroundInput, scheme: self.scheme))
                .foregroundColor(Color.clear)
                .background(.clear)
            )
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

struct TagButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var style: TagButtonStyle.styles = .primary
    
    enum styles{
        case primary
        case danger
        case success
        case pending
    }
    
    init(image: String? = nil, style: TagButtonStyle.styles = TagButtonStyle.styles.primary) {
        self.image = image
        self.style = style
    }
    
    var backgroundColor: Color{
        switch (self.style){
        case .pending:
            return Color("Pending").opacity(0.08)
        case .success:
            return Color("Active").opacity(0.08)
        case .danger:
            return Color("Danger").opacity(0.08)
        default:
            return Color("LightGray").opacity(0.08)
        }
    }
    var foregroundColor: Color{
        switch (self.style){
        case .pending:
            return Color("Pending")
        case .success:
            return Color("Active")
        case .danger:
            return Color("Danger")
        default:
            return Color("LightGray")
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack{
            if (self.image != nil && self.image!.isEmpty == false){
                ZStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(self.foregroundColor)
                }
                    .frame(width:16,height:16)
            }
            configuration.label
                .font(.caption)
                .foregroundColor(self.foregroundColor)
        }
            .frame(minHeight: 20)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(self.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct RemovableTagButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var style: TagButtonStyle.styles = .primary
    
    enum styles{
        case primary
        case danger
        case success
        case pending
    }
    
    init(image: String? = nil, style: TagButtonStyle.styles = TagButtonStyle.styles.primary) {
        self.image = image
        self.style = style
    }
    
    var backgroundColor: Color{
        switch (self.style){
        case .pending:
            return Color("Pending").opacity(0.08)
        case .success:
            return Color("Active").opacity(0.08)
        case .danger:
            return Color("Danger").opacity(0.08)
        default:
            return Color.get(.MiddleGray).opacity(0.08)
        }
    }
    var foregroundColor: Color{
        switch (self.style){
        case .pending:
            return Color("Pending")
        case .success:
            return Color("Active")
        case .danger:
            return Color("Danger")
        default:
            return Color.get(.MiddleGray)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack{
            if (self.image != nil && self.image!.isEmpty == false){
                ZStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(self.foregroundColor)
                }
                    .frame(width:16,height:16)
            }
            configuration.label
                .font(.caption)
                .foregroundColor(self.foregroundColor)
            ZStack{
                Image("cross")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(self.foregroundColor)
            }
            .frame(width: 16, height: 16)
        }
            .opacity(configuration.isPressed ? 0.5 : 1)
            .frame(minHeight: 20)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(self.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ContactButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var style: ContactButtonStyle.styles = .primary
    
    enum styles{
        case primary
        case danger
        case success
        case pending
    }
    
    init(image: String? = nil, style: ContactButtonStyle.styles = ContactButtonStyle.styles.primary) {
        self.image = image
        self.style = style
    }
    
    var backgroundColor: Color{
        switch (self.style){
        case .primary:
            return Whitelabel.Color(.Primary).opacity(0.08)
        case .pending:
            return Color.get(.Pending).opacity(0.08)
        case .success:
            return Color.get(.Active).opacity(0.08)
        case .danger:
            return Color.get(.Danger).opacity(0.08)
        default:
            return Color.get(.LightGray)
        }
    }
    var foregroundColor: Color{
        switch (self.style){
        case .primary:
            return Whitelabel.Color(.OnPrimary)
        case .pending:
            return Color.get(.Pending)
        case .success:
            return Color.get(.Active)
        case .danger:
            return Color.get(.Danger)
        default:
            return Color.get(.LightGray)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack{
            if (self.image != nil && self.image!.isEmpty == false){
                ZStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(self.foregroundColor)
                }
                    .frame(width:16,height:16)
            }
            configuration.label
                .font(.subheadline.weight(.medium))
                .foregroundColor(self.foregroundColor)
        }
            .frame(minHeight: 26)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(self.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct DashedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack(spacing:0){
            if (self.image != nil && self.image!.isEmpty == false){
                ZStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Whitelabel.Color(.Primary))
                }
                    .frame(width:16,height:16)
                    .padding(.trailing, 5)
            }
            configuration.label
                .foregroundColor(Whitelabel.Color(.Primary))
                .font(.subheadline.weight(.medium))
        }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
            .background(Whitelabel.Color(.Primary).opacity(0.08).clipShape(RoundedRectangle(cornerRadius: 14)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Whitelabel.Color(.Primary), style: .init(dash: [4,4]))
                .foregroundColor(Color.clear)
                .background(Color.clear)
            )
            .opacity(configuration.isPressed ? 0.5 : 1)
            
    }
}

struct ShutterButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var scheme: Color.CustomColorScheme = .auto
    
    init(scheme: Color.CustomColorScheme = .auto) {
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return ZStack{}
            .frame(maxWidth: 60,maxHeight: 60)
            .background(self.isEnabled ? (configuration.isPressed ? Color.white : Color.white.opacity(0.8)) : Color("Disabled"))
            .overlay(
                Circle()
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 4))
            )
            .clipShape(Circle())
            .padding(5)
            .background(configuration.isPressed ? Color.white : Color.white.opacity(0.8))
            .foregroundColor(self.isEnabled ? Whitelabel.Color(.Primary) : Color.get(.DisabledText))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
    }
}

struct CameraButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return ZStack{
            Image(self.image!)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.white)
        }
            .frame(maxWidth: 24,maxHeight: 24)
            .padding(16)
            .background(self.isEnabled ? (configuration.isPressed ? Color.white.opacity(0.4) : Color.white.opacity(0.2)) : Color("Disabled"))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
    }
}

extension NotificationButtonStyle{
    enum styles{
        case info
        case warning
    }
}

struct NotificationButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var style: NotificationButtonStyle.styles = .info
    
    init(style: NotificationButtonStyle.styles = .info) {
        self.style = style
    }
    
    var image: String{
        switch(self.style){
        default:
            return "info"
        }
    }
    var foreaground: Color{
        switch(self.style){
        default:
            return Color("LightGray")
        }
    }
    var background: Color{
        switch(self.style){
        default:
            return Color("LightGray").opacity(0.08)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return HStack(spacing: 12){
            ZStack{
                Image(self.image)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(self.foreaground)
            }
            .frame(width: 24, height: 24)
            configuration.label
                .foregroundColor(self.foreaground)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(16)
        .background(self.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct RadioButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    private var image: String? = nil
    private var description: LocalizedStringKey? = nil
    @Binding private var checked: Bool
    private var scheme: Color.CustomColorScheme = .auto
    
    init(image: String? = nil, description: LocalizedStringKey? = nil, checked: Binding<Bool> = .constant(false), scheme: Color.CustomColorScheme = .auto) {
        self.image = image
        self.description = description
        self._checked = checked
        self.scheme = scheme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        return 
        HStack(alignment:.center){
            ZStack{
                Circle()
                    .foregroundColor(Color.white)
                    .frame(maxWidth: 6, maxHeight: 6)
                    .zIndex(2)
                    .opacity(self.checked ? 1 : 0)
                Circle()
                    .foregroundColor(Whitelabel.Color(.Primary))
                    .zIndex(1)
                    .scaleEffect(self.checked ? 1 : 0)
            }
            .frame(maxWidth: 18, maxHeight: 18)
            .overlay(
                Circle()
                    .stroke(Color("Ocean"))
                    .scaleEffect(self.checked ? 0 : 1)
            )
            .padding(.trailing,5)
            if self.image != nil && self.image!.isEmpty == false{
                HStack{
                    Image(self.image!)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Whitelabel.Color(.Primary))
                        .frame(width: 18)
                }
                .frame(width:38,height:38)
                .background(Whitelabel.Color(.Primary).opacity(0.2))
                .clipShape(Circle())
                .padding(.trailing,5)
            }
            VStack(alignment:.leading,spacing:0){
                configuration.label
                    .font(.subheadline.bold())
                    .foregroundColor(Color("Text"))
                if (self.description != nil){
                    Text(self.description!)
                        .font(.caption)
                        .foregroundColor(Color("LightGray"))
                }
            }
            .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
            .stroke(Color("BackgroundInput"))
            .foregroundColor(Color.clear)
            .background(.clear)
            
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

enum ButtonSize{
    case normal
    case small
}

extension ButtonStyle where Self == NextButtonStyle{
    static func next(image: String? = nil, outline: Bool = false, scheme: Color.CustomColorScheme = .auto) -> NextButtonStyle {
        return NextButtonStyle(image: image, outlined: outline, scheme: scheme)
    }
}

extension ButtonStyle where Self == PassKeyButtonStyle{
    /**
        Password button key
     */
    static func passkey(scheme: Color.CustomColorScheme = .auto) -> PassKeyButtonStyle {
        return PassKeyButtonStyle(scheme: scheme)
    }
}

extension ButtonStyle where Self == DangerButtonStyle{
    static func danger(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> DangerButtonStyle {
        return DangerButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == RadioButtonSelector{
    static func radioSelector(isChecked: Binding<Bool>, image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> RadioButtonSelector {
        return RadioButtonSelector(checked: isChecked, image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle{
    static func secondary(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> SecondaryButtonStyle {
        return SecondaryButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == TertiaryButtonStyle{
    static func tertiary(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> TertiaryButtonStyle {
        return TertiaryButtonStyle(image: image, scheme: scheme)
    }
}


extension ButtonStyle where Self == SecondaryGrayButtonStyle{
    static func secondaryGray(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> SecondaryGrayButtonStyle {
        return SecondaryGrayButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle{
    static func primary(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> PrimaryButtonStyle {
        return PrimaryButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == SecondaryRoundedButtonStyle{
    /**
        Rounded icon with bottom text
     */
    static func secondaryRounded(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> SecondaryRoundedButtonStyle {
        return SecondaryRoundedButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == SecondaryNextButtonStyle{
    /**
        Next with fill
     */
    static func secondaryNext(image: String? = nil, scheme: Color.CustomColorScheme = .auto, size: ButtonSize = .normal) -> SecondaryNextButtonStyle {
        return SecondaryNextButtonStyle(image: image, scheme: scheme, size: size)
    }
}

extension ButtonStyle where Self == PlainButtonStyle{
    /**
        Plain button without additional elements
     */
    static func plain(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> PlainButtonStyle {
        return PlainButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == LinkButtonStyle{
    /**
        Plain button without additional elements
     */
    static func link(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> LinkButtonStyle {
        return LinkButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == DetailedButtonStyle{
    static func detailed(image: String? = nil, description: String? = nil, checked: Binding<Bool> = .constant(false), scheme: Color.CustomColorScheme = .auto) -> DetailedButtonStyle {
        return DetailedButtonStyle(image: image, description: description, checked: checked, scheme: scheme)
    }
}

extension ButtonStyle where Self == ActionButtonStyle{
    /**
        Action button
     */
    static func action(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> ActionButtonStyle {
        return ActionButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == TagButtonStyle{
    /**
        Tag button. Style define tag color
     */
    static func tag(image: String? = nil, style: TagButtonStyle.styles, scheme: Color.CustomColorScheme = .auto) -> TagButtonStyle {
        return TagButtonStyle(image: image, style: style)
    }
}

extension ButtonStyle where Self == RemovableTagButtonStyle{
    /**
        removable Tag button. Style define tag color
     */
    static func removableTag(image: String? = nil, style: TagButtonStyle.styles, scheme: Color.CustomColorScheme = .auto) -> RemovableTagButtonStyle {
        return RemovableTagButtonStyle(image: image, style: style)
    }
}

extension ButtonStyle where Self == ContactButtonStyle{
    /**
        Tag button. Style define tag color
     */
    static func contact(image: String? = nil, style: ContactButtonStyle.styles, scheme: Color.CustomColorScheme = .auto) -> ContactButtonStyle {
        return ContactButtonStyle(image: image, style: style)
    }
}

extension ButtonStyle where Self == DashedButtonStyle{
    /**
        Make dashed button, like upload file
     */
    static func dashed(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> DashedButtonStyle {
        return DashedButtonStyle(image: image)
    }
}

extension ButtonStyle where Self == ShutterButtonStyle{
    /**
        Camera shutter
     */
    static func shutter() -> ShutterButtonStyle {
        return ShutterButtonStyle()
    }
}

extension ButtonStyle where Self == CameraButtonStyle{
    /**
        Camera shutter
     */
    static func camera(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> CameraButtonStyle {
        return CameraButtonStyle(image: image)
    }
}

extension ButtonStyle where Self == NotificationButtonStyle{
    /**
        Notification
     */
    static func notification(style: NotificationButtonStyle.styles = .info, scheme: Color.CustomColorScheme = .auto) -> NotificationButtonStyle {
        return NotificationButtonStyle(style: style)
    }
}

extension ButtonStyle where Self == RadioButtonStyle{
    /**
        Radio Button
     */
    static func radio(image: String? = nil, description: LocalizedStringKey? = nil, checked: Binding<Bool> = .constant(false)) -> RadioButtonStyle {
        return RadioButtonStyle(image: image, description: description, checked: checked)
    }
}

extension ButtonStyle where Self == SecondaryDangerButtonStyle{
    static func secondaryDanger(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> SecondaryDangerButtonStyle {
        return SecondaryDangerButtonStyle(image: image, scheme: scheme)
    }
}

extension ButtonStyle where Self == SecondaryActiveButtonStyle{
    static func secondaryActive(image: String? = nil, scheme: Color.CustomColorScheme = .auto) -> SecondaryActiveButtonStyle {
        return SecondaryActiveButtonStyle(image: image, scheme: scheme)
    }
}

struct ButtonStylesPreview: View{
    @State private var state: Bool = false
    @State private var disabled: Bool = false
    
    var groupA: some View{
        VStack{
            Button("Toogle disabled \(disabled ? "[ON]" : "[OFF]")"){
                self.disabled = !self.disabled
            }
            Button{
                self.state = !self.state;
            } label:{
                VStack(alignment: .center, spacing:4){
                    ZStack{
                        Image("edit")
                    }
                    .frame(width: 20, height: 20)
                    Text("Edit")
                        .font(.body)
                        .foregroundColor(Whitelabel.Color(.Primary))
                }
            }.buttonStyle(.tertiary()).disabled(self.disabled)
        }
    }
    
    var body: some View{
        ScrollView{
            VStack{
                self.groupA
            }
            .padding()
        }
    }
}

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        ButtonStylesPreview()
    }
}
