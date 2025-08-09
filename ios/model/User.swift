//
//  User.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.10.2023.
//

import Foundation

enum CustomerStatus:String{
    case new = "0"
    case active = "1"
    case blocked = "2"
}

public struct Customer:Codable{
    var id:String
    var avatar: String?
    var firstName:String
    var lastName:String
    var email:String
    var mobile:String
    var dateOfBirth:String
    var emailConfirmed:Bool
    var pin:String?
    var pinChanged:Bool
    var address:String?
    var defaultAccountId:String?
    var status:Int?
    
    var fullName:String{
        return self.firstName + " " + self.lastName
    }
    
    var isVerified:Bool{
        if (self.status! == 2){
            return true
        }else{
            return false
        }
    }
    
    //MARK: Method will update customer avatar
    func updateAvatar(_ attachment: FileAttachment) async throws{
        //try await services.customers.uploadImage(self.id, attachment: attachment, documentTypeId: .avatar)
    }
}
