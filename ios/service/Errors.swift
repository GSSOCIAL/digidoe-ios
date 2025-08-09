//
//  Errors.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

protocol ServicesError:Error{
    var title: String { get set }
    var message: String? { get set }
    
    var localizedDescription: String {get}
}

struct ServiceError:ServicesError{
    var title:String
    var message:String?
    
    var localizedDescription:String{
        return self.message ?? "The operation couldn`t be completed."
    }
}

struct ActionError:ServicesError{
    var title:String
    var message:String?
    
    var dismissButtonLabel: String
    var dismissButtonAction: ()->Void
    var localizedDescription:String{
        return self.message ?? "The operation couldn`t be completed."
    }
}


struct ApiError: ServicesError{
    var title:String
    var message: String?
    
    mutating func parse(_ data: httpResponse) throws{
        let error = try JSONDecoder().decode(ApiErrorResponse.self, from: data.response)
        self.message = error.error.description
    }
}

struct ValidationError:Error{
    var title:String
    var message:String
    var field:String
}
struct InternalServerError:Error{
    var title:String
    var message:String
}

public struct ApiErrorDetail: Decodable{
    var message: String
    var target: String
}

public struct ApiErrorDetails: Decodable{
    enum ErrorCode: String, Decodable{
        case ModelValidationError
        case InsufficientPrivileges
    }
    
    var code: ErrorCode? = .ModelValidationError
    var details: Array<ApiErrorDetail>? = []
    var message: String?
    
    var description: String{
        var message = self.message ?? ""
        if (self.details != nil && self.details!.count > 0){
            var components: Array<String> = self.details!.filter({
                return $0.message.isEmpty == false
            }).map({
                return $0.message
            })
            if (!components.isEmpty){
                message = components.joined(separator: ". ")
            }
        }
        return message
    }
}

public struct ApiErrorResponse: Decodable{
    var error: ApiErrorDetails
}

public struct ApplicationError:Error{
    var title:String
    var message:String
}
