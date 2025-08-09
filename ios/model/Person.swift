//
//  Person.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation

public struct IndividualCustomer: Codable{
    public struct CreateIndividualCustomerRequest: Codable{
        public var personId: String
    }
    public struct CreateIndividualCustomerResponse: Codable{
        public var id: String
    }
}
public struct CustomersResponse: Codable{
    public var customers: Array<CustomersResponse.Customer> = []
    
    public struct Customer: Codable{
        var id: String
        var name: String
        var type: String
        var state: String
    }
}

public struct Person:Codable{
    public var address: PersonAddress?
    public var countryOfBirth: String?
    public var countryOfBirthExtId: Int?
    public var dateOfBirth: String
    public var dateOfDeath: String?
    public var email:String?
    public var gender: String
    public var genderExtId: Int?
    public var givenName: String?
    public var id: String
    public var middleName: String?
    public var phone: String?
    public var surname: String?
    public var edited: Bool? = false
    //public var prepopulatedOCRResults: Array<>
    
    public struct CreatePersonResponse: Codable{
        public var id: String
    }
    public struct PersonAddress: Codable{
        public var countryExtId: Int
        public var state: String?
        public var city: String?
        public var street: String
        public var building: String?
        public var postCode: String?
    }
    
    public struct CreatePersonRequest: Encodable{
        public var givenName: String?
        public var surname: String?
        public var middleName: String?
        
        public var dateOfBirth: String?
        public var dateOfDeath: String?
        public var countryOfBirthExtId: String?
        
        public var email: String
        public var phone: String
        public var genderExtId: String?
        public var address: PersonAddress?
        
        var prepopulatedOCRResults: KycpService.OCRDecodeResponse.OCRDecodeResult?
        var ocrOutputEdited: Bool? = nil
    }
}
