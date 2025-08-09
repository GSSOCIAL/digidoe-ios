//
//  Notification.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 04.04.2024.
//

import Foundation
import SwiftUI
import Combine

extension String{
    fileprivate func notificationFormatAsPrice(_ currency:String) -> String{
        var formatted = self
        let components = formatted.components(separatedBy: ".")
        
        var integer = components.count > 0 ? components[0] : "0"
        var coins = components.count == 2 ? components[1] : "0"
        
        if (coins.count == 1){
            coins = "\(coins)0"
        }
        coins = String(coins.prefix(2))
        
        var amount = Double(String((formatted as NSString).doubleValue)) ?? 0
        let isNegative = amount < 0
        
        return "0"
        /*
        MARK: RELEASE
        
        var price = "\(abs(Double(String((integer as NSString).doubleValue))!).notificationFormattedWithSeparator).\(coins)"
        return "\(isNegative ? "-" : "")\(currency) \(price)"
         */
    }
}

extension Formatter {
    fileprivate static let notificationWithSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}

extension Numeric {
    fileprivate var notificationFormattedWithSeparator: String { Formatter.notificationWithSeparator.string(for: self) ?? ""}
}

enum PushNotificationType{
    case CreateOrder
    case UserSignIn
    case DeleteContact
    case CreateContact
    case UpcomingSOPayment
    case FailedSOInsufficientFunds
    case NewSOCreated
    case FailedSOTechnIssue
    case FailedSOAccountClosed
    case StaleSOPushForCreator
    case OperationWaitingApproval
}

struct NotificationContextRow: Hashable{
    var label: String
    var value: String
    
    var hashValue: Int {
        return self.label.hashValue
    }

    static func == (lhs: NotificationContextRow, rhs: NotificationContextRow) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

protocol PushNotification{
    var type: PushNotificationType {get set}
    var title: String {get set}
    var body: String {get set}
    
    var label: String {get set}
    var context: Array<NotificationContextRow> {get}
    
    var operationId: String? {get}
    var sessionId: String? {get}
    var code: String? {get}
    
    var action: PushNotificationAction? {get}
    
    init(dictionary: [AnyHashable: Any])
}

enum PushNotificationAction{
    case confirm
    case router
}

//MARK: - Notifications
/// Confirm payment
struct CreateOrderNotification: PushNotification{
    var type: PushNotificationType = .CreateOrder
    var title: String = "DigiDoe Financial Solutions"
    var body: String = "To authorize the transaction, click here."
    var label: String = "Please authorize transaction";
    
    var reference: String?
    var operationId: String?
    var sessionId: String?
    var id: String?
    
    var code: String?
    var requestTimeStamp: String?
    var amount: String?
    var currencyCode: String?
    var contactAccountHolderName: String?
    var iban: String?
    var sortCode: String?
    var accountNumber: String?
    
    var action: PushNotificationAction? = .confirm
    
    init(dictionary: [AnyHashable: Any]){
        self.operationId = dictionary["operation_id"] as? String
        self.sessionId = dictionary["session_id"] as? String
        self.code = dictionary["code"] as? String
        self.id = dictionary["id"] as? String
        
        self.requestTimeStamp = (dictionary["data_requestTimeStamp"] as? String)?.replacingOccurrences(of: "\"", with: "")
        self.reference = dictionary["operationData_reference"] as? String
        self.amount = dictionary["operationData_amount_value"] as? String
        self.currencyCode = dictionary["operationData_amount_currency_code"] as? String
        self.contactAccountHolderName = dictionary["operationData_payee_contact.account_holder_name"] as? String
        self.iban = dictionary["operationData_debtor_account.identification.iban"] as? String
        self.sortCode = dictionary["operationData_debtor_account.identification.sort_code"] as? String
        self.accountNumber = dictionary["operationData_debtor_account.identification.account_number"] as? String
    }
    
    var context: Array<NotificationContextRow>{
        var date: String = ""
        var time: String = ""
        
        if (self.requestTimeStamp != nil){
            let timeComponents = self.requestTimeStamp!.split(separator: ".")
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let dateObject = formatter.date(from: String(timeComponents[0]))
            
            if (dateObject != nil){
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.string(from: dateObject!)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                time = timeFormatter.string(from: dateObject!)
            }
        }
        
        //Amount
        var amount: String = ""
        if (self.amount != nil){
            amount = self.amount!.notificationFormatAsPrice(self.currencyCode?.uppercased() ?? "")
        }
        
        return [
            .init(
                label: "Beneficiary",
                value: self.contactAccountHolderName ?? ""
            ),
            .init(
                label: "Amount",
                value: amount
            ),
            .init(
                label: "Reference",
                value: self.reference ?? ""
            ),
            .init(
                label: "Date",
                value: date
            ),
            .init(
                label: "Time",
                value: time
            ),
        ]
    }
}

/// Login
struct UserSignInNotification: PushNotification{
    var type: PushNotificationType = .UserSignIn
    var title: String = "DigiDoe Financial Solutions"
    var body: String = "To authorise login, click here"
    var label: String = "Please authorize login";
    
    var operationId: String?
    var sessionId: String?
    var code: String?
    var id: String?
    
    var requestTimeStamp: String?
    var ipAddress: String?
    
    var action: PushNotificationAction? = .confirm
    
    init(dictionary: [AnyHashable: Any]){
        self.operationId = dictionary["operation_id"] as? String
        self.sessionId = dictionary["session_id"] as? String
        self.requestTimeStamp = (dictionary["data_requestTimeStamp"] as? String)?.replacingOccurrences(of: "\"", with: "")
        self.code = dictionary["code"] as? String
        self.id = dictionary["id"] as? String
        self.ipAddress = (dictionary["data_ipAddress"] as? String)?.replacingOccurrences(of: "\"", with: "")
    }
    
    var context: Array<NotificationContextRow>{
        var date: String = ""
        var time: String = ""
        
        if (self.requestTimeStamp != nil){
            let timeComponents = self.requestTimeStamp!.split(separator: ".")
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let dateObject = formatter.date(from: String(timeComponents[0]))
            
            if (dateObject != nil){
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.string(from: dateObject!)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                time = timeFormatter.string(from: dateObject!)
            }
        }
        
        return [
            .init(
                label: "Device",
                value: self.ipAddress ?? ""
            ),
            .init(
                label: "Date",
                value: date
            ),
            .init(
                label: "Time",
                value: time
            )
        ]
    }
}

/// Delete contact
struct DeleteContactNotification: PushNotification{
    var type: PushNotificationType = .CreateOrder
    var title: String = "DigiDoe Financial Solutions"
    var body: String = "To authorise deletion of payee please click here"
    var label: String = "Please authorise payee deletion";
    
    var operationId: String?
    var sessionId: String?
    var code: String?
    var id: String?
    
    var accountHolderName: String?
    var requestTimeStamp: String?
    var sortCode: String?
    var accountNumber: String?
    var iban: String?
    
    var action: PushNotificationAction? = .confirm
    
    init(dictionary: [AnyHashable: Any]){
        self.operationId = dictionary["operation_id"] as? String
        self.sessionId = dictionary["session_id"] as? String
        self.code = dictionary["code"] as? String
        self.id = dictionary["id"] as? String
        
        self.accountHolderName = dictionary["operationData_account_holder_name"] as? String
        self.requestTimeStamp = (dictionary["data_requestTimeStamp"] as? String)?.replacingOccurrences(of: "\"", with: "")
        self.sortCode = dictionary["operationData_sort_code"] as? String
        self.accountNumber = dictionary["operationData_account_number"] as? String
        self.iban = dictionary["operationData_iban"] as? String
    }
    
    var context: Array<NotificationContextRow>{
        var date: String = ""
        var time: String = ""
        
        if (self.requestTimeStamp != nil){
            let timeComponents = self.requestTimeStamp!.split(separator: ".")
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let dateObject = formatter.date(from: String(timeComponents[0]))
            
            if (dateObject != nil){
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.string(from: dateObject!)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                time = timeFormatter.string(from: dateObject!)
            }
        }
        
        var output: Array<NotificationContextRow> = [
            .init(
                label: "Payee name",
                value: self.accountHolderName ?? ""
            )
        ]
        if (self.accountNumber != nil){
            output.append(.init(
                label: "Account Number",
                value: self.accountNumber ?? ""
            ))
            output.append(.init(
                label: "Sort Code",
                value: self.sortCode ?? ""
            ))
        }else{
            output.append(.init(
                label: "IBAN",
                value: self.iban ?? ""
            ))
        }
        output.append(.init(
            label: "Date",
            value: date
        ))
        return output
    }
}

/// Create contact
struct CreateContactNotification: PushNotification{
    var type: PushNotificationType = .CreateContact
    var title: String = "DigiDoe Financial Solutions"
    var body: String = "To authorise addition of payee please click here"
    var label: String = "Please authorise payee creation";
    
    var operationId: String?
    var sessionId: String?
    var code: String?
    var id: String?
    
    var accountHolderName: String?
    var requestTimeStamp: String?
    var sortCode: String?
    var accountNumber: String?
    var iban: String?
    
    var action: PushNotificationAction? = .confirm
    
    init(dictionary: [AnyHashable: Any]){
        self.operationId = dictionary["operation_id"] as? String
        self.sessionId = dictionary["session_id"] as? String
        self.code = dictionary["code"] as? String
        self.id = dictionary["id"] as? String
        
        self.accountHolderName = dictionary["operationData_account_holder_name"] as? String
        self.requestTimeStamp = (dictionary["data_requestTimeStamp"] as? String)?.replacingOccurrences(of: "\"", with: "")
        self.sortCode = dictionary["operationData_sort_code"] as? String
        self.accountNumber = dictionary["operationData_account_number"] as? String
        self.iban = dictionary["operationData_iban"] as? String
    }
    
    var context: Array<NotificationContextRow>{
        var date: String = ""
        var time: String = ""
        
        if (self.requestTimeStamp != nil){
            let timeComponents = self.requestTimeStamp!.split(separator: ".")
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let dateObject = formatter.date(from: String(timeComponents[0]))
            
            if (dateObject != nil){
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.string(from: dateObject!)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                time = timeFormatter.string(from: dateObject!)
            }
        }
        
        var output: Array<NotificationContextRow> = [
            .init(
                label: "Payee name",
                value: self.accountHolderName ?? ""
            )
        ]
        if (self.accountNumber != nil){
            output.append(.init(
                label: "Account Number",
                value: self.accountNumber ?? ""
            ))
            output.append(.init(
                label: "Sort Code",
                value: self.sortCode ?? ""
            ))
        }else{
            output.append(.init(
                label: "IBAN",
                value: self.iban ?? ""
            ))
        }
        output.append(.init(
            label: "Date",
            value: date
        ))
        return output
    }
}

/// MLS Confirmation
struct MlsDecisionConfirmationNotification: PushNotification{
    var type: PushNotificationType = .CreateContact
    var title: String = "DigiDoe Financial Solutions"
    var body: String = "To confirm decision, please click here."
    var label: String = "A request for a secure operation has been initiated on your profile. Please click approve if it was you."
    
    var operationId: String?
    var sessionId: String?
    var code: String?
    var id: String?
    
    var action: PushNotificationAction? = .confirm
    
    init(dictionary: [AnyHashable: Any]){
        self.operationId = dictionary["operation_id"] as? String
        self.sessionId = dictionary["session_id"] as? String
        self.code = dictionary["code"] as? String
        self.id = dictionary["id"] as? String
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

/// Standing Order soon
struct UpcomingSOPaymentNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .UpcomingSOPayment
    var title: String = "Standing order payment soon"
    var body: String = "Your standing order will be processed soon. Ensure your account is funded."
    var label: String = "Standing order payment soon";
    
    var action: PushNotificationAction? = .router
    
    var orderId: String
    var customerId: String
    var accountId: String
    
    init(dictionary: [AnyHashable: Any]){
        self.orderId = ""
        self.customerId = ""
        self.accountId = ""
        if (dictionary["data_orderId"] != nil){
            self.orderId = (dictionary["data_orderId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_customerId"] != nil){
            self.customerId = (dictionary["data_customerId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_accountId"] != nil){
            self.accountId = (dictionary["data_accountId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}
struct FailedSOInsufficientFundsNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .FailedSOInsufficientFunds
    var title: String = "Payment Failed"
    var body: String = "Your standing order could not be processed due to insufficient funds."
    var label: String = "Payment Failed";
    
    var action: PushNotificationAction? = .router
    
    var transactionId: String
    var customerId: String
    var accountId: String
    
    init(dictionary: [AnyHashable: Any]){
        self.transactionId = ""
        self.customerId = ""
        self.accountId = ""
        if (dictionary["data_transactionId"] != nil){
            self.transactionId = (dictionary["data_transactionId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_customerId"] != nil){
            self.customerId = (dictionary["data_customerId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_accountId"] != nil){
            self.accountId = (dictionary["data_accountId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

/// Notification on SO creation. Your SO
struct NewSOCreatedNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .NewSOCreated
    var title: String = "Standing Order Created"
    var body: String = "Your recurring payment has been set up successfully."
    var label: String = "Standing Order Created";
    
    var action: PushNotificationAction? = .router
    
    var orderId: String
    var customerId: String
    var accountId: String
    
    init(dictionary: [AnyHashable: Any]){
        self.orderId = ""
        self.customerId = ""
        self.accountId = ""
        if (dictionary["data_orderId"] != nil){
            self.orderId = (dictionary["data_orderId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_customerId"] != nil){
            self.customerId = (dictionary["data_customerId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_accountId"] != nil){
            self.accountId = (dictionary["data_accountId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

/// Notification on SO creation. Your SO
struct FailedSOTechnIssueNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .FailedSOTechnIssue
    var title: String = "Payment Failed"
    var body: String = "A technical issue prevented your standing order."
    var label: String = "Payment Failed";
    
    var action: PushNotificationAction? = .router
    
    var orderId: String
    var customerId: String
    var accountId: String
    
    init(dictionary: [AnyHashable: Any]){
        self.orderId = ""
        self.customerId = ""
        self.accountId = ""
        if (dictionary["data_orderId"] != nil){
            self.orderId = (dictionary["data_orderId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_customerId"] != nil){
            self.customerId = (dictionary["data_customerId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_accountId"] != nil){
            self.accountId = (dictionary["data_accountId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

/// Notification on SO creation. Your SO
struct FailedSOAccountClosedNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .FailedSOAccountClosed
    var title: String = "Account Closed"
    var body: String = "Payee account was closed according to the counterparty bank.We cancelled your standing order to prevent issues."
    var label: String = "Account Closed";
    
    var action: PushNotificationAction? = .router
    
    var orderId: String
    var customerId: String
    var accountId: String
    
    
    init(dictionary: [AnyHashable: Any]){
        self.orderId = ""
        self.customerId = ""
        self.accountId = ""
        if (dictionary["data_orderId"] != nil){
            self.orderId = (dictionary["data_orderId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_customerId"] != nil){
            self.customerId = (dictionary["data_customerId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_accountId"] != nil){
            self.accountId = (dictionary["data_accountId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

/// Notification on SO creation. Your SO
struct StaleSOPushForCreatorNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .StaleSOPushForCreator
    var title: String = "Standing order failed approval"
    var body: String = "Some participants missed the approval window. The standing order was сancelled"
    var label: String = "Standing order failed approval";
    
    var action: PushNotificationAction? = .router
    
    var orderId: String
    var customerId: String
    var accountId: String
    
    
    init(dictionary: [AnyHashable: Any]){
        self.orderId = ""
        self.customerId = ""
        self.accountId = ""
        if (dictionary["data_orderId"] != nil){
            self.orderId = (dictionary["data_orderId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_customerId"] != nil){
            self.customerId = (dictionary["data_customerId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
        if (dictionary["data_accountId"] != nil){
            self.accountId = (dictionary["data_accountId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

/// Notification on SO creation. Your SO
struct OperationWaitingApprovalNotification: PushNotification{
    var operationId: String? = ""
    var sessionId: String? = ""
    var code: String? = ""
    
    var type: PushNotificationType = .OperationWaitingApproval
    var title: String = "Approvment required"
    var body: String = "Operation waiting approval"
    var label: String = "Approvment required";
    
    var action: PushNotificationAction? = .router
    
    var flowId: String
    
    init(dictionary: [AnyHashable: Any]){
        self.flowId = ""
        if (dictionary["data_flowId"] != nil){
            self.flowId = (dictionary["data_flowId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").replacingOccurrences(of: "\r\n", with: #"\r\n"#).replacingOccurrences(of: "\"", with: "")
        }
    }
    
    var context: Array<NotificationContextRow>{
        return []
    }
}

// MARK: - Methods
/// Handle userInfo and transform into push notificaion if available
///
/// - Parameters:
///   - dictionary: Notification dictionary
///
/// - Returns:
///     - PushNotification?: Something
func obtainNotification(dictionary: [AnyHashable: Any]) -> PushNotification?{
    var type = dictionary["operation_type"] as? String
    //Notification model changed, check for type propertly also
    if (type == nil){
        type = dictionary["type"] as? String
    }
    switch(type?.lowercased()){
    case "createorder":
        return CreateOrderNotification(dictionary: dictionary)
    case "usersignin":
        return UserSignInNotification(dictionary: dictionary)
    case "deletecontact":
        return DeleteContactNotification(dictionary: dictionary)
    case "createcontact":
        return CreateContactNotification(dictionary: dictionary)
    case "mlsdecisionconfirmation":
        return MlsDecisionConfirmationNotification(dictionary: dictionary)
     case "upcomingsopayment":
        return UpcomingSOPaymentNotification(dictionary: dictionary)
    case "newsocreated":
        return NewSOCreatedNotification(dictionary: dictionary)
    case "failedsotechnissue":
        return FailedSOTechnIssueNotification(dictionary: dictionary)
    case "failedsoaccountclosed":
        return FailedSOAccountClosedNotification(dictionary: dictionary)
    case "stalesopushforcreator":
        return StaleSOPushForCreatorNotification(dictionary: dictionary)
    case "failedsoinsufficientfunds":
        return FailedSOInsufficientFundsNotification(dictionary: dictionary)
    case "operationwaitingapproval":
        return OperationWaitingApprovalNotification(dictionary: dictionary)
    default:
        break
    }
    return nil
}
