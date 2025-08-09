//
//  functions.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.10.2023.
//

import Foundation
import UIKit

func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

func topMostController() -> UIViewController {
    var topController: UIViewController = UIApplication.shared.windows.first!.rootViewController!
    while (topController.presentedViewController != nil) {
        topController = topController.presentedViewController!
    }
    return topController
}

func matches(for regex: String, in text: String) -> [String] {
    do{
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    }catch let error {
        return []
    }
}

func isStateForCountryExists(_ country: String) -> Bool{
    let modified = country.lowercased()
    return [
        "39463", //USA
        "usa",
        "united states",
        "us",
        "39264", //Canada
        "canada",
        "ca",
        "39327", //India
        "india",
        "in",
        "39254", //Brazil
        "brazil",
        "br",
        "39366", //Mexico
        "mexico",
        "mx",
        "39236", //Australia
        "australia",
        "au"
    ].first(where: {$0 == modified}) != nil
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

func randomId(length: Int) -> Int {
    let letters = "0123456789"
    return Int(String((0..<length).map{ _ in letters.randomElement()! }))!
}

func isContactDetailsMissing(_ contact: Contact) -> Bool {
    if (contact.currency.lowercased() == "eur"){
        if (contact.details.accountNumber == nil || contact.details.accountNumber!.isEmpty){
            if (contact.details.iban == nil || contact.details.swiftCode == nil || contact.details.iban!.isEmpty || contact.details.swiftCode!.isEmpty){
                return true
            }
        }
        //Check for address
        if (contact.details.address?.countryCode == nil || contact.details.address!.countryCode!.isEmpty){
            return true
        }
        if (isStateForCountryExists(contact.details.address!.countryCode!.uppercased()) && (contact.details.address?.state == nil || contact.details.address!.state!.isEmpty)){
            return true
        }
        if (contact.details.address?.street == nil || contact.details.address!.street!.isEmpty){
            return true
        }
        if (contact.details.address?.city == nil || contact.details.address!.city!.isEmpty){
            return true
        }
    }
    return false
}

func mimeTypeForFileExtension(_ fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "image/jpeg", "image/jpg":
        return "JPG"
    case "image/png":
        return "PNG"
    case "application/pdf":
        return "PDF"
    default:
        return fileExtension
    }
}
