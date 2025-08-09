//
//  DeviceDataService.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.02.2024.
//

import Foundation
import UIKit
import FirebaseMessaging
import FirebaseAuth
import Firebase
import FirebaseCore

class DeviceDataService{
    /**
     Return application version number
     */
    var applicationVersion: String{
        let service = AppVersion()
        return service.current
    }
    
    /**
     Return application build number
     */
    var applicationBuild: String{
        let service = AppVersion()
        return service.build
    }
    
    /**
     Return OS version, e.g ios 16
     */
    var operatingSystem: String{
        return String((UIDevice.current.systemVersion as NSString).floatValue)
    }
    
    /**
     Return device name
     */
    var deviceName: String{
        return UIDevice.current.name
    }
    
    /**
     Return device unique id
     */
    var deviceId: String{
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    func fireBaseId() async throws -> String{
        return try await Installations.installations().installationID()
    }
    
    /**
     Obtain Firebase token if available
     */
    var fireBaseToken: String{
        if let fcm = Messaging.messaging().fcmToken {
            print("[DEVICE REGISTER][FCM TOKEN]     -",fcm)
            return fcm
        }
        return ""
    }
    
    func refreshFBCTok() async throws{
        Messaging.messaging().deleteToken{ error in
            print("[FCM][FCM TOKEN]     -", error)
        }
        try await Messaging.messaging().token()
    }
}
