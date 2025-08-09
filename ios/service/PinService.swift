//
//  PinService.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.12.2023.
//

import Foundation

class pin{
    let key:String="pincode"
    
    var hasPin:Bool{
        let defaults = UserDefaults.standard
        if defaults.value(forKey: self.key) != nil{
            return true
        }
        return false
    }
    
    func verify(_ pin:String)->Bool{
        return pin == self.pin
    }
    
    func set(_ pin:String){
        let defaults = UserDefaults.standard
        defaults.set(pin, forKey: self.key)
        defaults.synchronize()
    }
}

fileprivate extension pin{
    var pin:String{
        if self.hasPin{
            let defaults = UserDefaults.standard
            return defaults.string(forKey: self.key)!
        }
        return ""
    }
}
