//
//  AppVersion.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 23.12.2023.
//

import Foundation

class AppVersion:ObservableObject{
    var current:String{
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
        return nsObject as? String ?? "0"
    }
    
    var build:String{
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleVersion"] as AnyObject
        return nsObject as! String
    }
}

extension AppVersion{
    func isOutdatedWith(version: String) -> Bool{
        let compareWith = version.split(separator: ".")
        let current = (self.current).split(separator: ".")
        
        //MARK: Due version has some digits in version - check in dumb mode
        var isOldVersion = false;
        var isFreshVersion = false;
        
        var i = 0;
        while (i < compareWith.count && isOldVersion == false && isFreshVersion == false){
            //MARK: Compare each component
            let actualComponent: String = String(compareWith[i])
            let currentComponent: String? = current.count - 1 >= i ? String(current[i]) : nil
            
            if (currentComponent == nil){
                isOldVersion = true
                break
            }
            if (Int(actualComponent)! > Int(currentComponent!)!){
                isOldVersion = true
                break
            }
            if (Int(currentComponent!)! > Int(actualComponent)!){
                isFreshVersion = true
                break
            }
            i += 1
        }
        return isOldVersion
    }
    
    func hasUpdates() async throws -> Bool{
        do{
            let info = try await self.getAppInfo()
            
            let actual = (info.results.first?.version ?? "0").split(separator: ".")
            let current = (self.current).split(separator: ".")
            
            //MARK: Due version has some digits in version - check in dumb mode
            var isOldVersion = false;
            var isFreshVersion = false;
            
            var i = 0;
            while (i < actual.count && isOldVersion == false && isFreshVersion == false){
                //MARK: Compare each component
                let actualComponent: String = String(actual[i])
                let currentComponent: String? = current.count - 1 >= i ? String(current[i]) : nil
                
                if (currentComponent == nil){
                    isOldVersion = true
                    break
                }
                if (Int(actualComponent)! > Int(currentComponent!)!){
                    isOldVersion = true
                    break
                }
                if (Int(currentComponent!)! > Int(actualComponent)!){
                    isFreshVersion = true
                    break
                }
                i += 1
            }
            return isOldVersion
        }catch let error{
            throw error
        }
    }
    
    fileprivate func getAppInfo() async throws -> LookupResult{
        guard let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String,
        let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)")
        else{
            throw ApplicationError(title: "", message: "Unable to fetch appstore result")
        }
        
        var request = URLRequest(url:url)
        request.httpMethod = "get"
        
        var (responseData,_) = try await URLSession.shared.data(for:request)
        let decoded = try JSONDecoder().decode(LookupResult.self, from: responseData)
        return decoded
    }
}

fileprivate class LookupResult: Decodable {
    var results: [AppInfo]
}

fileprivate class AppInfo: Decodable {
    var version: String
    var trackViewUrl: String
}
