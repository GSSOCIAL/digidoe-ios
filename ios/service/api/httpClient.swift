//
//  httpClient.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

public struct Request<Response>{
    var method:String!
    var url:String!
    var query:[String:String]?
    var body:Data?
    var headers:[String:String]? = [:]
}

extension Request{
    public static func get(_ url:String,query:[String:String]? = nil)->Request{
        Request(method: "GET", url: url, query: query)
    }
    public static func post(_ url:String,body:Data?)->Request{
        Request(method: "POST", url: url, body: body)
    }
    public static func patch(_ url:String,body:Data?)->Request{
        Request(method: "PATCH", url: url, body: body)
    }
    public static func put(_ url:String,body:Data?)->Request{
        Request(method: "PUT", url: url, body: body)
    }
    public static func delete(_ url:String)->Request{
        Request(method: "DELETE", url: url)
    }
}

struct httpResponse{
    var statusCode:Int=0
    var response:Data
}

struct httpError:Error{
    var code:Int=0
    var title:String
    var description:String?
}

struct MultipartField{
    var key: String
    var value: String?
    
    var data: Data?
    var filename: String?
    var fileType: FileAttachment.mimeTypesLabel?
    
    init(key: String, value: String){
        self.key = key
        self.value = value
    }
    
    init(key: String, value: Int){
        self.key = key
        self.value = String(value)
    }
    
    init(key: String, value: Data, filename: String, fileType: FileAttachment.mimeTypesLabel?){
        self.key = key
        self.data = value
        self.filename = filename
        self.fileType = fileType
    }
    
}

struct Multipart{
    private let boundary: String = UUID().uuidString
    var fields: [MultipartField] = []
    
    private let separator: String = "\r\n"
    
    var BoundarySeparator: String{
        return ("--\(self.boundary)\(self.separator)")
    }
    
    private func disposition(_ key: String) -> String {
        return "Content-Disposition: form-data; name=\"\(key)\""
    }
    
    public var httpContentTypeHeadeValue: String {
        return "multipart/form-data; boundary=\(self.boundary)"
    }
    
    var formdata: Data{
        var data: Data = .init()
        
        var i = 0
        while(i<self.fields.count){
            data.append(self.BoundarySeparator)
            print(self.BoundarySeparator)
            if (self.fields[i].value != nil){
                data.append(disposition(fields[i].key) + self.separator)
                data.append(self.separator)
                data.append(fields[i].value! + self.separator)
                
                print(disposition(fields[i].key) + self.separator)
                print(fields[i].value!)
            }else{
                var type = ""
                if fields[i].fileType != nil{
                    if FileAttachment.mimeType.withLabel(fields[i].fileType!.rawValue) != nil{
                        type = FileAttachment.mimeType.withLabel(fields[i].fileType!.rawValue)!.rawValue
                    }
                }
                data.append(disposition(fields[i].key) + "; filename=\"\(fields[i].filename!)\"" + self.separator)
                data.append("Content-Type: \(type ?? "image/jpg")" + self.separator + self.separator)
                data.append(fields[i].data!)
                data.append(self.separator)
                
                print(disposition(fields[i].key) + "; filename=\"\(fields[i].filename!)\"")
                print("Content-Type: \(fields[i].fileType?.rawValue ?? "image/jpg")")
                print("***image-data***")
            }
            
            i += 1
        }
        
        data.append("--\(self.boundary)--")
        print("--\(self.boundary)--")
        return data
    }
}

class httpClient{
    var session:URLSession!
    var base: String!
    var headers:[String:String]=[:]
    
    var beforeRequest: (_ request:Request<Any>) async throws -> Request<Any> = {
        request in
        return request
    }
    /*
    var afterRequest: ((Data?,URLResponse?,Error?,Request<Any>,@escaping ((Data?,Int) ->Void))->(data:Data?,response:URLResponse?,error:Error?,request:Request<Any>,completion:((Data?,Int)->Void),replaceRequest:Bool)) = {
        (data,response,error,request,completion) in
        return (data,response,error,request,completion,false)
    }*/
    var afterRequest: (Data?, URLResponse?, Request<Any>) async throws -> (data:Data?, response: URLResponse?, request: Request<Any>, replace:Bool) = {
        (data,response,request) in
        return (data,response,request,false)
    }
    
    struct ServerError: ServicesError{
        var title: String = "Failed"
        var message: String? = "This is server error. Please try again"
    }
    
    init(_ base:String,headers:[String:String]){
        self.base = base
        self.headers = headers
        self.session = URLSession(configuration: .default)
        
        self.session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if headers.count > 0{
            self.session.configuration.httpAdditionalHeaders = headers
        }
    }
    
    /*
     Send GET Request
     */
    func get(_ url:String) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        var request = Request<Any>.get(endpoint)
        request.headers = self.headers
        
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response )
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform GET request")
        }
    }
    
    /*
     Send POST Request
    */
    func post(_ url:String,body:Encodable?=nil) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        var data:Data = (["":""]).toJSON()!
        
        if let body = body{
            data = body.toJSON()!
        }
        
        var request = Request<Any>.post(endpoint,body: data)
        request.headers = self.headers
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response)
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform POST request")
        }
    }
    
    func post(_ url:String,body:Data?=nil) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        var data:Data = (["":""]).toJSON()!
        
        if let body = body{
            data = body
        }
        
        var request = Request<Any>.post(endpoint,body: data)
        request.headers = self.headers
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response)
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform POST request")
        }
    }
    
    func post(_ url: String, body: Multipart) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        
        var request = Request<Any>.post(endpoint,body: body.formdata)
        request.headers = self.headers
        request.headers?["Content-Type"] = body.httpContentTypeHeadeValue
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response)
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform POST Multipart request")
        }
    }
    
    /*
     Send PATCH Request
    */
    func patch(_ url:String,body:Encodable?=nil) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        var data:Data = (["":""]).toJSON()!
        
        if let body = body{
            data = body.toJSON()!
        }
        
        var request = Request<Any>.patch(endpoint,body: data)
        request.headers = self.headers
        
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response )
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform PATCH request")
        }
    }
    
    /*
     Send PUT Request
     */
    func put(_ url:String,body:Encodable?=nil) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        var data:Data = (["":""]).toJSON()!
        
        if let body = body{
            data = body.toJSON()!
        }
        
        var request = Request<Any>.put(endpoint,body: data)
        request.headers = self.headers
        
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response )
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform PUT request")
        }
    }
    
    /*
     Send DELETE Request
     */
    func delete(_ url:String,body:Encodable?=nil) async throws -> httpResponse{
        let endpoint = self.buildEndpoint(url)
        var data:Data = (["":""]).toJSON()!
        
        if let body = body{
            data = body.toJSON()!
        }
        
        var request = Request<Any>.delete(endpoint)
        request.headers = self.headers
        
        do{
            let (response,code,_) = try await self.send(request)
            return httpResponse(statusCode: code, response: response )
        }catch let error{
            if let error = error as? AuthenticationService.RefreskTokenError{
                throw error
            }else if let error = error as? InternalServerError{
                throw error
            }else if let error = error as? ServicesError{
                throw error
            }
            throw httpError(code:0,title:"Unable to perform DELETE request")
        }
    }
    
    /*
     Build endpoint url with base
     */
    func buildEndpoint(_ url:String!)->String{
        return "\(self.base!)\(url!)"
    }
    
    func makeRequest(_ request: Request<Any>!) -> URLRequest {
        let endpoint = URL(string: request.url)!
        var httpRequest = URLRequest(url: endpoint)
        httpRequest.httpMethod = request.method
        httpRequest.cachePolicy = .reloadIgnoringCacheData
        
        if request.body !=  nil{
            httpRequest.httpBody = request.body
        }
        
        if request.headers!.count > 0{
            for header in request.headers!{
                if httpRequest.value(forHTTPHeaderField: header.key) == nil{
                    httpRequest.setValue(header.value, forHTTPHeaderField: header.key)
                }
            }
        }
        
        return httpRequest
    }
    
    /**
     Actually Send request
    */
    func send(_ data: Request<Any>) async throws -> (Data, Int, URLResponse?){
        //Use beforeRequest handler
        let requestProps = try await self.beforeRequest(data)
        let request = self.makeRequest(requestProps)
        #if DEBUG
        print("Send request to \(request.url)")
        #endif
        do{
            var (responseData,response) = try await URLSession.shared.data(for:request)
            let urlResponse = response as? HTTPURLResponse
            if let code = urlResponse?.statusCode{
                print("\(code)")
                if code == 500{
                    #if DEBUG
                    print("[API][\(requestProps.method)][\(request.url)][\(code)]    -",try JSONSerialization.jsonObject(with: responseData))
                    #endif
                    throw InternalServerError(title: "Failed", message: "This is server issue. Please try again later")
                }
                if code == 504{
                    #if DEBUG
                    print("[API][\(requestProps.method)][\(request.url)][\(code)]    -",try JSONSerialization.jsonObject(with: responseData))
                    #endif
                    throw InternalServerError(title: "Failed", message: "This is server issue. Please try again")
                }
                if code == 502{
                    #if DEBUG
                    print("[API][\(requestProps.method)][\(request.url)][\(code)]    -",try JSONSerialization.jsonObject(with: responseData))
                    #endif
                    throw InternalServerError(title: "Failed", message: "This is server issue. Please try again later")
                }
            }
            let wrapped = try await self.afterRequest(responseData,response,data)
            responseData = wrapped.data!
            response = wrapped.response!
            
            #if DEBUG
            print([
                "endpoint":request.url,
                "body":request.httpBody,
                "method":request.httpMethod,
                "response": responseData,
                "responseCode": (response as! HTTPURLResponse).statusCode
            ])
            #endif
            
            return (responseData,(response as! HTTPURLResponse).statusCode,response)
        }catch let error{
            #if DEBUG
            print("Request \(request.url) failed:")
            print(error)
            #endif
            throw(error)
        }
    }
}
