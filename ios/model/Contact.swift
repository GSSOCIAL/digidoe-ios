//
//  Contact.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.01.2024.
//

import Foundation

public struct Contact: Codable, Identifiable{
    public typealias ID = String
    public var id: String {
        return contactId ?? ""
    }
    
    public var contactId: String?
    public var accountId: String?
    public var type: Contact.ContactType
    public var currency: String
    public var accountHolderName:String
    public var details: ContactDetails
    
    public enum ContactType:String,Codable{
        case ABA
        case sortCode = "sort_code"
        case IBAN
        case israeliLocal = "israeli_local"
        case USD = "USD"
    }
    
    public struct ContactDetails: Codable{
        public var legalType: Contact.ContactDetails.ContactLegalType
        public var accountNumber: String?
        public var sortCode: String?
        public var swiftCode: String?
        public var iban: String?
        public var address: Contact.ContactDetails.ContactAddress?
        
        public enum ContactLegalType:String,Codable{
            case PRIVATE
            case BUSINESS
        }
        
        public struct ContactAddress: Codable{
            public var countryCode: String?
            public var state: String?
            public var city: String?
            public var street: String?
            public var building: String?
            public var postCode: String?
            public var countryName: String?
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(contactId)
    }
    
    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        return lhs.contactId == rhs.contactId
    }
}
