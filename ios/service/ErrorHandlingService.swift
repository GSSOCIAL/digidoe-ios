//
//  ErrorHandlingService.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation
import SwiftUI

class ErrorHandlingService:ObservableObject{
    @Published var hasError = false
    @Published var hasMessageError = false
    @Published var isSystemError = false
    @Published var error: Error?
    
    var title: String{
        get {
            var title = "Something went wrong"
            if let error = self.error as? ServiceError{
                title = error.title
            }
            return title
        }
        set {  }
    }
    
    var message: String{
        get {
            var message = "The operation couldn`t be completed"
            if let error = self.error as? ServiceError{
                message = error.localizedDescription
            }else if let error = error as? ApplicationError{
                message = error.message
            }else if self.error?.localizedDescription != nil{
                message = self.error!.localizedDescription
            }
            return message
        }
        set {  }
    }
}

extension ErrorHandlingService{
    func handle(_ error:Error){
        self.error = error
        self.hasMessageError = false
        self.isSystemError = false
        if (error as? AuthenticationService.RefreskTokenError != nil){
            Task{
                do{
                    let service = DeviceDataService()
                    try await service.refreshFBCTok()
                }
            }
            self.isSystemError = true
        }
        if ((error as? ApplicationError) == nil && !self.isSystemError){
            self.hasMessageError = true
        }
        self.hasError = true
    }
}

///Display & format alert
func displayAlert(error:Error?) -> (()->Alert){
    return {
        var title: String = "Something went wrong"
        var message: String? = ""
        
        if error != nil{
            if let error = error as? KycpService.ApiError{
                message = error.getMessage()
            }else if let error = error as? KycpService.KycpSimpleError{
                message = error.getMessage()
            }else if let error = error as? KycpService.KycpError{
                title = error.title
                message = error.getMessage()
            }else if let error = error as? KycpService.KycpServerError{
                message = error.getMessage()
            }else if let error = error as? ServicesError{
                title = error.title
                message = error.message
            }else if let error = error as? AuthenticationService.RefreskTokenError{
                title = error.title
                message = error.message
            }else if let error = error as? InternalServerError{
                title = error.title
                message = error.message
            }
            
            if (message == nil || message?.isEmpty == true){
                if error?.localizedDescription != nil{
                    message = error!.localizedDescription
                }else{
                    message = "The operation couldn`t be completed"
                }
            }
            
            if (message == nil || message?.isEmpty == true){
                if error?.localizedDescription != nil{
                    message = error!.localizedDescription
                }else{
                    message = "The operation couldn`t be completed"
                }
            }
            
            if let error = error as? AuthenticationService.RefreskTokenError{
                return Alert(
                    title: Text("Session expired"),
                    message: Text("Your session has expired. Please sign in again"),
                    dismissButton: .default(Text("OK"),action: {
                        DispatchQueue.main.async {
                            let center = NotificationCenter.default
                            let notificationName = Notification.Name("logout")
                            center.post(name:notificationName,object: nil)
                        }
                    })
                )
            }
            if let error = error as? ActionError{
                return Alert(
                    title: Text(LocalizedStringKey(title)),
                    message: Text(LocalizedStringKey(message!)),
                    dismissButton: .default(Text(LocalizedStringKey(error.dismissButtonLabel)),action: error.dismissButtonAction)
                )
            }
        }
        
        return Alert(
            title: Text(LocalizedStringKey(title)),
            message: Text(LocalizedStringKey(message!))
        )
    }
}

struct KycpServerError: Error, Decodable{
        var errors: Array<KycpServerErrorDetails> = []
        var isCancelled: Bool = false
        var isSuccess: Bool = false
        
        func getMessage() -> String{
            return self.errors.map({
                return "\($0.code): \($0.description)"
            }).joined(separator: ".")
        }
        
        struct KycpServerErrorDetails: Decodable{
            var code: String?
            var data: String?
            var description: String
        }
    }
