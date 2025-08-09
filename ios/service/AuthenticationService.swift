//
//  AuthenticationService.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation
import Combine
import SwiftUI
import CryptoKit
import AuthenticationServices

extension AuthenticationService{
    enum AuthenticateState: Equatable{
        case initialized
        case authenticating
        case accessCodeReceived(code: String)
        case authenticated
        case registred
        case error(Error)
        case failed
        case cancelled
        
        static func == (lhs: AuthenticationService.AuthenticateState, rhs: AuthenticationService.AuthenticateState) -> Bool {
            switch(lhs,rhs){
            case (.initialized, .initialized):
                return true
            case (.authenticating, .authenticating):
                return true
            case (.accessCodeReceived (let lhsCode), .accessCodeReceived (let rhsCode)):
                return lhsCode == rhsCode
            case (.authenticated, .authenticated):
                return true
            case (.registred, .registred):
                return true
            case (.error (let lhsError), .error (let rhsError)):
                return true
            case (.failed, .failed):
                return true
            case (.cancelled, .cancelled):
                return true
            default:
                return false
            }
        }
    }
    
    enum PKCE {
        /// Generate Code Verifier
        /// - Returns:
        ///     - String: Code Verifier
        static func generateCodeVerifier() -> String {
            var buffer = [UInt8](repeating: 0, count: 32)
            let status = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
            if status == errSecSuccess {
                return PKCE.base64URLEncode(octets: buffer)
            }
            return generateCodeVerifier()
        }
        
        /// Generate code challenge
        /// - Parameters:
        ///     - string:
        /// - Returns:
        ///     - String?: Code Challenge
        static func generateCodeChallenge(from string: String) -> String? {
            guard let data = string.data(using: .utf8) else { return nil }
            let hashed = SHA256.hash(data: data)
            return Data(hashed).pkce_base64EncodedString()
        }
        
        static func base64URLEncode(octets: [UInt8]) -> String {
            let data = Data(bytes: octets, count: octets.count)
            return data
                .base64EncodedString()                    // Regular base64 encoder
                .replacingOccurrences(of: "=", with: "")  // Remove any trailing '='s
                .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
                .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
                .trimmingCharacters(in: .whitespaces)
        }
    }
    
    struct AccessToken: Equatable, Decodable {
        var id_token: String
        var access_token: String
        var expires_in: Double
        var token_type: String?
        var refresh_token: String
        var scope: String?
    }

    struct AccessTokenData:Decodable{
        var customer_id: String
        var email: String?
        var phone: String?
        var username: String?
        var accountNotRequested: Bool = false
    }
    struct RefreskTokenError:Error{
        var title:String
        var message:String?
        
        var localizedDescription:String{
            return self.message ?? "The operation couldn`t be completed."
        }
    }
}

extension AuthenticationService{
    /// Request for new request token
    func getRefreshToken() async throws -> String{
        var request = URLRequest(url: self.getRefreshTokenURL())
        request.httpMethod = "POST"
        
        request.setValue("1.0", forHTTPHeaderField: "x-api-version")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var data:Data = try self.refreshTokenData()
        request.httpBody = data
        
        var (responseData,response) = try await URLSession.shared.data(for:request)
        let httpResponse = response as? HTTPURLResponse
        
        if httpResponse != nil && httpResponse!.statusCode == 200{
            let token = try JSONDecoder().decode(AccessToken.self,from: responseData)
            
            //MARK: Save access token to storage
            let defaults = UserDefaults.standard
            defaults.setValue(responseData,forKey: "accessToken")
            defaults.synchronize()
            
            return token.access_token
        }else{
            DispatchQueue.main.async {
                let center = NotificationCenter.default
                let notificationName = Notification.Name("logout")
                center.post(name:notificationName,object: nil)
            }
            throw RefreskTokenError(title: "Unable to get refresh token \(httpResponse!.statusCode)")
        }
    }
}

//MARK: - URL Formatters
extension AuthenticationService{
    /// Get authorize URL
    /// - Parameters:
    ///     - codeChallenge: Code Challenge
    /// - Returns:
    ///     - URL: Authorize url
    func authorizeURL(codeChallenge: String, query: URL?) -> URL {
        var components = URLComponents(string: URL(string:Enviroment.authenticationBaseUrl)!.absoluteString)!

        components.queryItems = [
            URLQueryItem(
                name: "client_id",
                value: Enviroment.authenticationClientId
            ),
            URLQueryItem(
                name: "code_challenge",
                value: codeChallenge
            ),
            URLQueryItem(
                name: "code_challenge_method",
                value: "S256"
            ),
            URLQueryItem(
                name: "redirect_uri",
                value: Enviroment.authenticationRedirectUri
            ),
            URLQueryItem(
                name: "response_type",
                value: Enviroment.authenticationResponseType
            ),
            URLQueryItem(
                name: "scope",
                value: Enviroment.authenticationScopes.joined(separator: " ")
            ),
            URLQueryItem(
                name: "prompt",
                value: "login"
            ),
            URLQueryItem(
                name: "tenant",
                value: Whitelabel.Tenant()
            )
        ]
        
        if (query != nil){
            var token = ""
            var src = ""
            let queryComponents = URLComponents(string: query!.absoluteString)
            if (queryComponents != nil){
                if (queryComponents!.queryItems?.first(where: {$0.name == "token"}) != nil){
                    token = queryComponents!.queryItems!.first(where: {$0.name == "token"})!.value ?? ""
                }
                if (queryComponents!.queryItems?.first(where: {$0.name == "src"}) != nil){
                    src = queryComponents!.queryItems!.first(where: {$0.name == "src"})!.value ?? ""
                }
            }
            
            let inviteQueryItem = URLQueryItem(name: "acr_values", value: "flow:invite token:\(token) src:\(src)")
            components.queryItems?.append(inviteQueryItem)
        }
        return components.url!
    }
    
    /// Get access token URL
    /// - Parameters:
    ///     - code:
    ///     - codeVerifier:
    /// - Returns:
    ///     - URL: Access token url
    func accessTokenURL(code: String, codeVerifier: String) -> URL {
        let components = URLComponents(string: URL(string:Enviroment.authenticationTokenUrl)!.absoluteString)!
        return components.url!
    }
    
    /// Get access token query
    /// - Parameters:
    ///     - code:
    ///     - codeVerifier:
    /// - Returns:
    ///     - Data: Query data
    func accessTokenData(code: String, codeVerifier: String) -> Data{
        return "client_id=\(Enviroment.authenticationClientId)&client_secret=\(Enviroment.authenticationClientSecret.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)&code_verifier=\(codeVerifier)&code=\(code)&grant_type=\(Enviroment.authenticationGrantType)&redirect_uri=\(Enviroment.authenticationRedirectUri)&state=xxx&scope=\(Enviroment.authenticationScopes.joined(separator: " "))".data(using: .utf8)!
    }
    
    /// Get refresh token query
    /// - Returns:
    ///     - Data: Query data
    func refreshTokenData() throws -> Data{
        let defaults = UserDefaults.standard
        if defaults.value(forKey: "accessToken") != nil{
            let token = try JSONDecoder().decode(AccessToken.self,from: defaults.data(forKey: "accessToken")!)
            return "refresh_token=\(token.refresh_token)&grant_type=refresh_token&client_id=\(Enviroment.authenticationClientId)&client_secret=\(Enviroment.authenticationClientSecret.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)".data(using: .utf8)!
        }
        throw ApplicationError(title: "", message: "Access token is missing")
    }
    
    /// Get refresh token URL
    /// - Returns:
    ///     - URL: Access token url
    func getRefreshTokenURL() -> URL{
        let components = URLComponents(string: URL(string:Enviroment.authenticationRefreshTokenUrl)!.absoluteString)!
        return components.url!
    }
}

//MARK: - Authentication data formatters
extension AuthenticationService{
    static func obtainDataFromAccessToken(token:AccessToken) throws -> AccessTokenData{
        guard let parsed = token.id_token.components(separatedBy: ".")[1] as? String else{
            throw ServiceError(title: "Unable to decode token")
        }
        guard let decodedString = try parsed.base64Decode() as? String else{
            throw ServiceError(title: "Unable to decode token")
        }
        guard let userData = try JSONSerialization.jsonObject(with:Data(decodedString.utf8)) as? [String:Any] else{
            throw ServiceError(title: "Unable to decode token", message: "Unable to parse JSON data")
        }
        guard let customerId = userData["sub"] as? String else{
            throw ServiceError(title: "Unable to decode token", message: "User missing")
        }
        
        let email = userData["email"] as? String
        let phone = userData["phone"] as? String
        let username = userData["username"] as? String
        let accountNotRequested = userData["account_not_requested"] as? String ?? "False"
        
        return AccessTokenData(
            customer_id: customerId,
            email: email,
            phone: phone,
            username: username,
            accountNotRequested: accountNotRequested.lowercased() == "true" ? true : false
        )
    }
}

//MARK: - Authentification methods
extension AuthenticationService{
    /// Call login
    /// - Parameters:
    ///     - url: Override url
    func login(_ url: URL?) async throws{
        self.state = .authenticating
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .AuthenticationStateChange, object: nil, userInfo: [
                "state": AuthenticateState.authenticating
            ])
        }
        self.codeVerifier = PKCE.generateCodeVerifier()
        
        var endUrl = self.authorizeURL(
            codeChallenge: PKCE.generateCodeChallenge(from: self.codeVerifier)!,
            query: url
        )
        
        let signInPromise = Future<URL, Error> { completion in
            self.session = ASWebAuthenticationSession(
                url: endUrl,
                callbackURLScheme: "digidoeauth"
            ) { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
            
            self.session!.presentationContextProvider = self
            self.session!.prefersEphemeralWebBrowserSession = true
            self.session!.start()
        }
        
        signInPromise.sink { (completion) in
            switch completion {
            case .failure(let error):
                let _error = ApplicationError(
                    title: "",
                    message: "User cancel authentication process"
                )
                self.state = .error(_error)
                NotificationCenter.default.post(name: .AuthenticationStateChange, object: nil, userInfo: [
                    "state": AuthenticateState.error(_error)
                ])
                break;
            default:
                break;
            }
        } receiveValue: { (url) in
            self.processResponseURL(url)
        }
        .store(in: &self.subscriptions)
    }
    
    /// Process response url
    /// - Parameters:
    ///     - url: Override url
    func processResponseURL(_ url: URL?){
        Task{
            do{
                guard url != nil else{
                    throw ApplicationError(
                        title: "Unable to authenticate",
                        message: "User cancel authentication process"
                    )
                }
                
                let query = URLComponents(string: url!.absoluteString)?.queryItems
                guard let code = query?.first(where: {$0.name == "code"}) else{
                    throw ApplicationError(
                        title: "Unable to handle authorization",
                        message: "Auth code is missing"
                    )
                }
                self.state = .accessCodeReceived(code: code.value ?? "")
                NotificationCenter.default.post(name: .AuthenticationStateChange, object: nil, userInfo: [
                    "state": AuthenticateState.accessCodeReceived(code: code.value ?? "")
                ])
            }catch(let error){
                self.state = .error(error)
                NotificationCenter.default.post(name: .AuthenticationStateChange, object: nil, userInfo: [
                    "state": AuthenticateState.error(error)
                ])
            }
        }
    }
    
    /// Process acess code
    /// - Parameters:
    ///     - code: Access code
    func processAccessCode(_ code: String?) async throws{
        guard code != nil else{
            throw ApplicationError(title: "", message: "Access Code Empty")
        }
        
        var request = URLRequest(
            url: self.accessTokenURL(code: code!, codeVerifier: self.codeVerifier)
        )
        request.httpMethod = "POST"
        request.setValue("1.0", forHTTPHeaderField: "x-api-version")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        var requestData:Data = self.accessTokenData(code:code!, codeVerifier: codeVerifier)
        request.httpBody = requestData
        
        var (data,response) = try await URLSession.shared.data(for:request)
        let httpResponse = response as? HTTPURLResponse
        
        guard httpResponse != nil && httpResponse?.statusCode == 200 else{
            self.state = .error(ApplicationError(title: "", message: "Failed to exchange token"))
            NotificationCenter.default.post(name: .AuthenticationStateChange, object: nil, userInfo: [
                "state": AuthenticateState.error(ApplicationError(title: "", message: "Failed to exchange token"))
            ])
            return
        }
        let decoded = try JSONSerialization.jsonObject(with: data)
        let token = try JSONDecoder().decode(AccessToken.self,from: data)
        let defaults = UserDefaults.standard
        defaults.setValue(data,forKey: "accessToken")
        defaults.synchronize()
        
        self.state = .authenticated
        NotificationCenter.default.post(name: .AuthenticationStateChange, object: nil, userInfo: [
            "state": AuthenticateState.authenticated
        ])
        self.codeVerifier = ""
    }
}

//MARK: - Authentification methods
extension AuthenticationService{
    /// Send device data to BE service
    func processDevice() async throws -> ProfileService.DeviceRegisterResultResult{
        return try await services.profiles.registerDevice()
    }
}

class AuthenticationService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding{
    var session: ASWebAuthenticationSession?
    
    @Published var state: AuthenticationService.AuthenticateState = .initialized
    @Published var codeVerifier: String = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    var onThrow: (Error) -> Void = { _ in }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
