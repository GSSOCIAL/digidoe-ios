//
//  models.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 29.06.2025.
//
import Foundation
import Combine
import SwiftUI

enum PaymentRails: String, Codable, CaseIterable{
    case fps
    case sepa
    case swift
    case bacs
    case digidoe
}

enum PaymentScheme: String, Codable, CaseIterable{
    case sepaNormal
    case sepaInstant
    case bacsDD
    case chaps
}

enum OrderCurrentState: String, Codable, CaseIterable{
    case received
    case pendingApproval
    case pending
    case accepted
    case completed
    case rejected
    case cancelled
}

public struct AmountDto: Codable{
    var currencyCode: CurrencyCode
    var value: Double
    
    enum CurrencyCode: String, Codable, CaseIterable{
        case usd
        case eur
        case gbp
    }
}

public struct OrderPriceComponentDto: Codable{
    var paymentOrderId: String
    var feeId: String
    var feeDescription: String?
    var amount: AmountDto?
    var sourceAccountId: String
    var destinationAccountId: String
}

public struct StandingOrderDto: Codable{
    var id: String
    var description: String?
    var period: CreateStandingOrderRequestModel.CreateStandingOrderPeriod
    var startDate: String
    var endDate: String?
    var totalOperations: Int?
    var state: StandingOrderState
    var nextExecutionDate: String
    
    enum StandingOrderState: String, Codable, CaseIterable{
        case pending
        case active
        case completed
        case cancelled
        
        var label: String{
            switch self {
            case .pending:
                return "Pending"
            case .active:
                return "Active"
            case .completed:
                return "Completed"
            case .cancelled:
                return "Cancelled"
            }
        }
        
        var group: String{
            switch self {
            case .pending:
                return "Pending"
            case .active:
                return "Active"
            case .completed:
                return "Completed"
            case .cancelled:
                return "Cancelled"
            }
        }
        
        var color: Color{
            switch self {
            case .pending:
                return Color.get(.Pending)
            case .active:
                return Color.get(.Active)
            case .completed:
                return Color.get(.Active)
            case .cancelled:
                return Color.get(.Danger)
            }
        }
    }
}

public struct AccountSimpleDto: Codable{
    public var id: String
    public var baseCurrencyCode: String
    //public var type: AccountSimpleType
    public var identification: IdentificationSimpleDto
    public var title: String?
    public var ownerName: String?
    public var sortOrder: Int
    public var bankName: String?
    public var bankAddress: String?
    public var bankId: String?
    public var currentBalance: AmountDto?
    public var availableBalance: AmountDto?
    
    public enum AccountSimpleType: String, Codable, CaseIterable{
        case payments
        case operating
        case mmb
        case unrecognizedFunds
    }
}

public struct IdentificationSimpleDto: Codable{
    public var id: String
    public var sortCode: String?
    public var accountNumber: String?
    public var iban: String?
    public var bban: String?
}

public struct RecipientSimpleDto: Codable{
    public var accountHolderName: String?
    public var currency: String
    public var legalType: RecipientSimpleDtoLegalType
    public var accountId: String?
    public var sortCode: String?
    public var accountNumber: String?
    public var iban: String?
    public var swiftCode: String?
    
    public enum RecipientSimpleDtoLegalType: String, Codable, CaseIterable{
        case PRIVATE
        case BUSINESS
    }
}

struct PaymentOrderExtendedDto: Codable{
    var id: String
    var createdBy: String?
    var createdUtc: String
    var reference: String?
    var requestedExecutionDate: String?
    var paymentRails: PaymentRails
    var paymentScheme: PaymentScheme?
    var currentState: OrderCurrentState
    var paymentPurposeText: String?
    var amount: AmountDto?
    var debtorAccountId: String
    var payeeContactId: String?
    var endToEndTransactionId: String?
    var orderPriceComponents: Array<OrderPriceComponentDto>?
    //var fraudAlerts: String?
    var standingOrder: StandingOrderDto?
    var debtorAccount: AccountSimpleDto?
    var recipient: RecipientSimpleDto?
    var displayState: DisplayState
    var cancellationReason: String?
    
    enum PaymentOrderExtendedDisplayState: String, Codable, CaseIterable{
        case pending
        case failed
        case completed
    }
    
    enum DisplayState: String, Codable, CaseIterable{
        case pending
        case failed
        case completed
    }
}

public struct CreateStandingOrderRequestModel: Codable{
    public var description: String?
    public var endDate: String?
    public var isConfirmed: Bool
    public var period: CreateStandingOrderPeriod
    public var startDate: String
    public var totalOperations: Int?
    
    public enum CreateStandingOrderPeriod: String, Codable, CaseIterable{
        case daily
        case weekly
        case biweekly
        case monthly
        case quarterly
        case yearly
        
        var label: String{
            switch self {
            case .daily:
                return "Daily"
            case .weekly:
                return "Weekly"
            case .biweekly:
                return "Biweekly"
            case .monthly:
                return "Monthly"
            case .quarterly:
                return "Quarterly"
            case .yearly:
                return "Yearly"
            }
        }
        
        func frequency(_ startDate: Date) -> String{
            var dayOfWeek = startDate.asString("EEEE")
            var dateOfMonth = startDate.asString("dd")
            var month = startDate.asString("MMM")
            
            switch self{
            case .daily:
                return "daily"
            case .biweekly:
                return "every 2 weeks on \(dayOfWeek)"
            case .weekly:
                return "every \(dayOfWeek)"
            case .monthly:
                return "on the \(dateOfMonth) of each month"
            case .quarterly:
                return "every 3 month on the \(dateOfMonth)"
            case .yearly:
                return "every \(month) \(dateOfMonth)"
            }
            return ""
        }
    }
}
