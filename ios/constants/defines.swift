//
//  defines.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct Option{
    public var id: String
    public var label: String
    public var props: [String:String] = [:]
    
    init(id: String, label: String, props: [String:String] = [:]) {
        self.id = id
        self.label = label
        self.props = props
    }
}

var IdentityDocumentTypes: Array<UploadIdentityView.DocumentType> = [
    .init(id: .passport, key: "passport", label: "Passport", image: "passport", description: "Face photo page"),
    .init(id: .proofOfAddress, key: "driverLicense", label: "Driver’s license", image: "directions-car", description: "Face and back"),
    .init(id: .idCard, key: "identityCard", label: "Identity Card", image: "id-card", description: "Face and back"),
    .init(id: .residencePermit, key: "residencePermit", label: "Residence Permit", image: "id-card", description: "Face and back")
]

var ProofOfAddressDocumentTypes: Array<UploadIdentityView.DocumentType> = [
    .init(id: .proofOfAddress, key: "utilityBill", label: "Utility Bill", image: "receipt", description: "Upload your document"),
    .init(id: .proofOfAddress, key: "bankStatement", label: "Bank Statement", image: "receipt-item", description: "Upload your document"),
    .init(id: .proofOfAddress, key: "driverLicense", label: "Driver’s license", image: "directions-car", description: "Face and back")
]

/**
 User input time when task will start
 */
let userDefaultInputLagTimeNanoSeconds: UInt64 = 1_000_000_000; 

/*
 .font(.body) = 16px
 .font(title2) = 20px
 .font(subheadline) = 14px
 .font(caption) = 12px
 .font(caption2) = 10px
 */
