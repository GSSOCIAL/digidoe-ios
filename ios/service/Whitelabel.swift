//
//  Whitelabel.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 31.07.2025.
//
import SwiftUI
import Foundation

struct WhitelabelModel: Codable{
    let Colors: WhitelabelColorModel
    let Branding: WhitelabelBrandingModel
    
    struct WhitelabelColorModel: Codable{
        var Fill: WhitelabelFillModel
        var Text: WhitelabelTextModel
        
        struct WhitelabelFillModel: Codable{
            var Primary: ColorModel
            var Secondary: ColorModel
            var Tertiary: ColorModel
            var Quaternary: ColorModel
        }
        
        struct WhitelabelTextModel: Codable{
            var OnPrimary: ColorModel
            var OnSecondary: ColorModel
            var OnTertiary: ColorModel
            var OnQuaternary: ColorModel
        }
    }
    
    struct WhitelabelBrandingModel: Codable{
        var Name: String
    }
    
    struct ColorModel: Codable{
        let light: String
        let dark: String
        
        private enum CodingKeys: String, CodingKey {
            case light = "light"
            case dark = "dark"
        }
    }
}

struct WhitelabelEnviroment: Codable{
    var tenant: String
}

public enum Whitelabel{
    enum ColorsKeys: String{
        case Primary
        case OnPrimary
        case Secondary
        case OnSecondary
        case Tertiary
        case OnTertiary
        case Quaternary
        case OnQuaternary
    }
    
    enum ColorScheme: String{
        case light
        case dark
        case auto
    }
    
    enum ImageKeys: String{
        case logo
        case logoSmall
        case icon
    }
    
    static let resource: WhitelabelEnviroment = {
        let url = Bundle.main.path(
            forResource: "Whitelabel-Info",
            ofType: "plist"
        )
        if (url == nil){
            fatalError("Unable to access property list Whitelabel-Info.plist")
        }
        
        let data = try? Data(contentsOf: URL(fileURLWithPath: url!))
        if (data == nil){
            fatalError("Unable to get property list Whitelabel-Info.plist")
        }
        
        do{
            return try PropertyListDecoder().decode(WhitelabelEnviroment.self, from: data!)
        }catch{
            fatalError("Unable to decode whitelabel property list Whitelabel-Info.plist")
        }
    }()
    
    static let data: WhitelabelModel? = {
        let resource = Whitelabel.resource
        let url = Bundle.main.path(
            forResource: "\(resource.tenant)-Info",
            ofType: "plist"
        )
        if (url == nil){
            fatalError("Unable to access property list \(resource.tenant)-Info.plist")
        }
        let data = try? Data(contentsOf: URL(fileURLWithPath: url!))
        if (data == nil){
            fatalError("Unable to get property list \(resource.tenant)-Info.plist")
        }
        do{
            return try PropertyListDecoder().decode(WhitelabelModel.self, from: data!)
        }catch{
            fatalError("Unable to decode whitelabel property list \(resource.tenant)-Info.plist")
        }
        return nil
    }()
    
    static func BrandName() -> String{
        let data = self.data
        if (data != nil){
            return data!.Branding.Name
        }
        return ""
    }
    
    static func Tenant() -> String{
        let resource = self.resource
        return resource.tenant
    }
    
    static func Color(_ name: Whitelabel.ColorsKeys, scheme: Whitelabel.ColorScheme? = .auto) -> Color{
        let data = self.data
        if (data != nil){
            //Get color scheme
            switch(name){
            case .Primary:
                return SwiftUI.Color(
                    hex: data!.Colors.Fill.Primary.light
                )
            case .OnPrimary:
                return SwiftUI.Color(
                    hex: data!.Colors.Text.OnPrimary.light
                )
            case .Secondary:
                return SwiftUI.Color(
                    hex: data!.Colors.Fill.Secondary.light
                )
            case .OnSecondary:
                return SwiftUI.Color(
                    hex: data!.Colors.Text.OnSecondary.light
                )
            case .Tertiary:
                return SwiftUI.Color(
                    hex: data!.Colors.Fill.Tertiary.light
                )
            case .OnTertiary:
                return SwiftUI.Color(
                    hex: data!.Colors.Text.OnTertiary.light
                )
            case .Quaternary:
                return SwiftUI.Color(
                    hex: data!.Colors.Fill.Quaternary.light
                )
            case .OnQuaternary:
                return SwiftUI.Color(
                    hex: data!.Colors.Text.OnQuaternary.light
                )
            }
        }
        return SwiftUI.Color.white.opacity(0)
    }
    
    static func Color(_ name: Whitelabel.ColorsKeys, scheme: SwiftUI.Color.CustomColorScheme) -> Color{
        var customScheme: Whitelabel.ColorScheme = .auto
        
        if (scheme == .light){
            customScheme = .light
        }else{
            customScheme = .dark
        }
        
        return Whitelabel.Color(name,scheme: customScheme)
    }
    
    static func Image(_ name: Whitelabel.ImageKeys) -> String{
        let resource = Whitelabel.resource
        
        switch (name){
        case .logo:
            return "Whitelabel/\(resource.tenant)/logo"
        case .logoSmall:
            return "Whitelabel/\(resource.tenant)/small"
        case .icon:
            return "Whitelabel/\(resource.tenant)/app"
        }
    }
}
