//
//  Organisation.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.11.2023.
//

import Foundation

public struct Organisation:Codable{
    public var id: String
    public var legalName: String
    public var brandName: String
    public var registrationNumber: String
    public var dateOfIncorporation: String
    public var countryOfIncorporationExtId: Int
    public var address: OrganisationAddress
    
    public struct OrganisationAddress: Codable{
        public var countryExtId: Int
        public var state: String?
        public var city: String?
        public var street: String
        public var building: String?
        public var postCode: String?
    }
    
    public struct CreateOrganisationRequest: Codable{
        public var legalName: String
        public var brandName: String
        public var registrationNumber: String
        public var dateOfIncorporation: String
        public var countryOfIncorporationExtId: String
        public var address: OrganisationAddress
    }
}
