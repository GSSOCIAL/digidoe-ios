//
//  Identity.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

class IdentityService:BaseHttpService{
    override var base:String! { Enviroment.apiIdentity }
    
    func logout() async throws{
        do{
            let defaults = UserDefaults.standard
            var token = ""
            if defaults.value(forKey: "accessToken") != nil{
                let data = try JSONDecoder().decode(AuthenticationService.AccessToken.self,from: defaults.data(forKey: "accessToken")!)
                token = data.id_token
            }
            let url = "connect/endsession?id_token_hint=\(token)&state=&post_logout_redirect_uri=\(Enviroment.logoutRedirectUri.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
            try await self.client.get(url)
        }catch let error{
            throw(error)
        }
    }
}
