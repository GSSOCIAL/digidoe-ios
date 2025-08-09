//
//  Biometrics.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 23.12.2023.
//

import Foundation

class Biometrics{
    static func isEnabled() -> Bool{
        let defaults = UserDefaults.standard
                            
        var enabled = true
        if defaults.value(forKey: "useBiometrics") != nil{
            enabled = defaults.bool(forKey: "useBiometrics")
        }
        
        return enabled
    }
    
    static func enable(){
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: "useBiometrics")
        }
    }
    
    static func disable(){
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            defaults.set(false, forKey: "useBiometrics")
        }
    }
}
