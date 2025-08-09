//
//  Transaction.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.10.2023.
//

import Foundation
import SwiftUI

struct BankTransaction:Encodable{
    enum CodingKeys:String,CodingKey{
        case id
    }
    var id:String
    var amount:Double
    var status:Int
    var type:Int
    
    init(_ data:[String:Any]){
        self.id = data["id"] as! String
        self.amount = data["amount"] as! Double
        self.status = data["status"] as! Int
        self.type = data["type"] as! Int
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
    }
    
}

struct Transaction: Codable{
    var amount: Double
    var balance: Double
    var bankAddress: String?
    var bankTransactionAccountOwnerName: String?
    var contactId: String?
    var counterpartAccountNumber: String?
    var counterpartAddress: String?
    var counterpartIban: String?
    var counterpartName: String?
    var counterpartSortCode: String?
    var creationDate: String
    var currency: String
    var currentState: state
    var endToEndTransactionId: String
    var executionDate: String
    var linkedTransactionId: String?
    var number: Int
    var paymentRails: paymentRails
    var paymentScheme: paymentScheme?
    var reference: String?
    var transactionId: String
    var transactionSubType: transactionSubType?
    var hasAttachments: Bool
    var hasStandingOrder: Bool
    
    public enum paymentRails: String, Codable{
        case fps
        case sepa
        case swift
        case bacs
        case digidoe
    }
    public enum paymentScheme: String, Codable{
        case sepaNormal
        case sepaInstant
        case bacsDD
        case chaps
    }
    public enum transactionSubType: String, Codable{
        case `internal` = "internal"
        case inbound
        case outbound
    }
    
    public enum state: String, Codable, CaseIterable{
        case pending
        case confirmed
        case inReview
        case authorized
        case cancelled
        case processing
        case failed
        case rejected
        case completed
        
        var label: String{
            switch self{
            case .pending:
                return "Pending"
            case .confirmed:
                return "Confirmed"
            case .inReview:
                return "In review"
            case .authorized:
                return "Authorized"
            case .cancelled:
                return "Cancelled"
            case .processing:
                return "Processing"
            case .failed:
                return "Failed"
            case .rejected:
                return "Rejected"
            case .completed:
                return "Completed"
            }
        }
        var color: Color{
            switch self{
            case .pending, .confirmed, .authorized:
                return Color.get(.Pending)
            case .completed:
                return Color.get(.Active)
            case .cancelled, .rejected, .failed:
                return Color.get(.Danger)
            default:
                return Color.get(.LightGray)
            }
        }
    }
    
    func DateObject() -> Date?{
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: self.creationDate)
    }
    
    func schemeAsString() -> String{
        return self.paymentScheme?.rawValue ?? "-"
        /*
        if self.scheme != nil && self.scheme!.isEmpty == false{
            let scheme = self.scheme!
            if transactionSchemes[scheme.lowercased()] != nil{
                return transactionSchemes[scheme.lowercased()]!
            }
            return scheme
        }
        return ""
         */
    }
}
