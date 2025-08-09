//
//  Enviroment.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

var EnviromentOverrideUseMockData: Bool = false

public enum Enviroment{
    enum Keys {
        enum AuthenicationList{
            static let authenticationUrl = "AUTHENTICATION_URL"
            static let tokenUrl = "AUTHENTICATION_TOKEN_URL"
            static let refreshTokenUrl = "AUTHENTICATION_REFRESHTOKEN_URL"
            static let acrValues = "AUTHENICATION_ACRVALUES"
            static let responseType = "AUTHENICATION_RESPONSE_TYPE"
            static let scopes = "AUTHENICATION_SCOPES"
            static let redirectUri = "AUTHENICATION_REDIRECT_URI"
            static let clientId = "AUTHENICATION_CLIENT_ID"
            static let clientSecret = "AUTHENICATION_CLIENT_SECRET"
            static let grantType = "AUTHENICATION_GRANT_TYPE"
            static let logoutRedirectUri = "AUTHENTICATION_LOGOUT_REDIRECT_URI"
        }
        
        enum Plist{
            static let apiBase = "API_BASE"
            static let apiIs = "API_IS"
            static let deleteSession = "DELETE_SESSION"
            static let feedbackEmail = "FEEDBACK_EMAIL"
            static let shareUrl = "SHARE_URL"
            static let appUrl = "APP_URL"
            static let useMockData = "USE_MOCK_DATA"
            static let apiKycp = "API_KYCP"
            static let apiIdentity = "API_IDENTITY"
            static let universalLinkHostForRegister = "AASA_REGISTER_HOST"
            static let storageBase = "STORAGE_URL"
            static let platformBase = "PLATFORM_BASE"
        }
    }
    
    private static let infoDictionary:[String:Any] = {
        guard let dictionary = Bundle.main.infoDictionary else{
            fatalError("Plist file not found")
        }
        return dictionary
    }()
    
    static let apiBase:String = {
        guard let baseApiString = Enviroment.infoDictionary[Keys.Plist.apiBase] as? String else{
            fatalError("Api base variable not set")
        }
        return baseApiString
    }()
    
    static let storageBase:String = {
        guard let endpoint = Enviroment.infoDictionary[Keys.Plist.storageBase] as? String else{
            fatalError("Storage url variable not set")
        }
        return endpoint
    }()
    
    static let apiIs:String = {
        guard let baseApiString = Enviroment.infoDictionary[Keys.Plist.apiIs] as? String else{
            fatalError("IS api variable not set")
        }
        return baseApiString
    }()
    
    static let deleteSession:Bool = {
        let value:String = Enviroment.infoDictionary[Keys.Plist.deleteSession] as? String ?? "1"
        return value == "1"
    }()
    
    static let feedbackEmail:String = {
        return Enviroment.infoDictionary[Keys.Plist.feedbackEmail] as? String ?? ""
    }()
    
    static let shareUrl:String = {
        return Enviroment.infoDictionary[Keys.Plist.shareUrl] as? String ?? ""
    }()
    
    static let appUrl:String = {
        return Enviroment.infoDictionary[Keys.Plist.appUrl] as? String ?? ""
    }()
    
    //MARK: Authenication below
    static let authenticationBaseUrl:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.authenticationUrl] as? String ?? ""
    }()
    
    static let authenticationTokenUrl:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.tokenUrl] as? String ?? ""
    }()
    
    static let authenticationRefreshTokenUrl:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.refreshTokenUrl] as? String ?? ""
    }()
    
    static let authenticationAcrValues:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.acrValues] as? String ?? ""
    }()
    
    static let authenticationResponseType:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.responseType] as? String ?? ""
    }()
    
    static let authenticationScopes:[String] = {
        let scopes = Enviroment.infoDictionary[Keys.AuthenicationList.scopes] as? String
        return scopes?.components(separatedBy: ",") as? [String] ?? []
    }()
    
    static let authenticationRedirectUri:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.redirectUri] as? String ?? ""
    }()
    
    static let authenticationClientId:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.clientId] as? String ?? ""
    }()
    
    static let authenticationClientSecret:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.clientSecret] as? String ?? ""
    }()
    
    static let authenticationGrantType:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.grantType] as? String ?? ""
    }()
    
    static let useMockData:Bool = {
        if (EnviromentOverrideUseMockData){
            return true
        }
        let value: String = Enviroment.infoDictionary[Keys.Plist.useMockData] as? String ?? "0"
        return value == "1"
    }()
    
    static let logoutRedirectUri:String = {
        return Enviroment.infoDictionary[Keys.AuthenicationList.logoutRedirectUri] as? String ?? ""
    }()
    
    static let apiKYCP:String = {
        guard let baseApiString = Enviroment.infoDictionary[Keys.Plist.apiKycp] as? String else{
            fatalError("KYCP api variable not set")
        }
        return baseApiString
    }()
    
    static let apiIdentity: String = {
        guard let identityApiString = Enviroment.infoDictionary[Keys.Plist.apiIdentity] as? String else{
            fatalError("Identity Api variable not set")
        }
        return identityApiString
    }()
    
    static let universalLinkHostForRegister: String = {
        guard let hostString = Enviroment.infoDictionary[Keys.Plist.universalLinkHostForRegister] as? String else{
            fatalError("Unable to find register AASA host")
        }
        return hostString
    }()
    
    static let platformUrl: String = {
        guard let endpoint = Enviroment.infoDictionary[Keys.Plist.platformBase] as? String else{
            fatalError("Platform base variable not set")
        }
        return endpoint
    }()
    static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
