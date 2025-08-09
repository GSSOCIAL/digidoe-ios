//
//  Profile.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.02.2024.
//

import Foundation

extension ProfileService{
    
    enum ConfirmationType: String, Codable{
        case OtpEmail
        case Push
    }
    
    enum ConfirmationState: String, Codable{
        case Pending
        case Confirmed
        case Rejected
        case Timeout
    }
    
    struct SessionOperationNotFoundError: Error{
        
    }
    
    struct ConfirmationSessionCreateDtoResult: Codable{
        var value: ConfirmationSessionCreateDto
        
        struct ConfirmationSessionCreateDto: Codable{
            var contactDisplayName: String?
            var id: String
            var timestamp: String
            var expiresAt: String
            var ttl: Int
            var operationTimestamp: String
            var operationExpiresAt: String
            var operationTtl: Int
            var resendDelay: Int
            var type: ConfirmationType
            var operationId: String
            var state: ConfirmationState
        }
    }
    
    struct ConfirmationSessionDtoResult: Codable{
        var value: ConfirmationSessionDto
        
        struct ConfirmationSessionDto: Codable{
            var contactDisplayName: String?
            var id: String
            var timestamp: String
            var expiresAt: String
            var type: ConfirmationType
            var operationId: String
            var state: ConfirmationState
            var attempts: Int
            var resendDelay: Int
        }
    }
    
    struct ConfirmationStateResult: Codable{
        var value: ConfirmationState
    }
    
    ///Initiate OTP session
    func sessionInitiate(_ operationId: String) async throws -> ConfirmationSessionCreateDtoResult{
        let response = try await self.client.post("profile/session/initiate",body: [
            "operationId":operationId
        ])
        //Operation not found
        if (response.statusCode == 404){
            throw SessionOperationNotFoundError()
        }
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(ConfirmationSessionCreateDtoResult.self,from:response.response)
    }
    
    ///Confirm OTP session
    func sessionConfirm(operationId: String, sessionId: String, code: String) async throws -> ConfirmationSessionDtoResult{
        let response = try await self.client.post("profile/session/confirm",body: [
            "operationId":operationId,
            "sessionId":sessionId,
            "code":code
        ])
        
        //Operation not found
        if (response.statusCode == 404){
            throw SessionOperationNotFoundError()
        }
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(ConfirmationSessionDtoResult.self,from:response.response)
    }
    
    /// Check session status
    func sessionStatus(operationId: String, sessionId: String) async throws -> ConfirmationStateResult{
        let response = try await self.client.get("profile/operation/\(operationId)/state/\(sessionId)")
        
        //Operation not found
        if (response.statusCode == 404){
            throw SessionOperationNotFoundError()
        }
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(ConfirmationStateResult.self,from:response.response)
    }
    
    ///Reject OTP session
    func sessionReject(operationId: String, sessionId: String, code: String) async throws -> ConfirmationSessionDtoResult{
        let response = try await self.client.post("profile/session/reject",body: [
            "operationId":operationId,
            "sessionId":sessionId,
            "code":code
        ])
        //Operation not found
        if (response.statusCode == 404){
            throw SessionOperationNotFoundError()
        }
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(ConfirmationSessionDtoResult.self,from:response.response)
    }
}

class ProfileService:BaseHttpService{
    override var base:String! { Enviroment.apiIdentity }
    
    struct CreateOrUpdateDeviceInfoRequest: Codable{
        var deviceId: String
        var deviceType: DeviceType = .Mobile
        var deviceName: String
        var fcmToken: String
        var platform: String
        var operationSystem: String
        var applicationVersion: String
        
        enum DeviceType: String, Codable{
            case Mobile
            case Browser
            case Undefined
        }
    }
    
    struct DeviceInfoDtoResult: Codable{
        var value: DeviceRegisterResultResult.DeviceRegisterResult.DeviceInfoDto
    }
    
    struct DeviceInfoDtoListResult: Codable{
        var value: Array<DeviceRegisterResultResult.DeviceRegisterResult.DeviceInfoDto>
    }
    
    struct DeviceRegisterResultResult: Codable{
        var value: DeviceRegisterResult
        
        struct DeviceRegisterResult: Codable{
            var registrationResult: DeviceRegistrationResult
            var deviceInfo: DeviceInfoDto
            
            enum DeviceRegistrationResult: String, Codable{
                case Registered
                case AlreadyRegistered
            }
            
            struct DeviceInfoDto: Codable{
                var id: String
                var createdUtc: String
                var updatedUtc: String?
                var deviceName: String?
                var deviceId: String?
                var platform: String?
                var operationSystem: String?
                var userAgent: String?
                var applicationVersion: String?
                var firstIpAddress: String?
                var lastIpAddress: String?
                var isTrusted: Bool
                var deviceType: CreateOrUpdateDeviceInfoRequest.DeviceType
            }
        }
    }
    
    func registerDevice() async throws -> DeviceRegisterResultResult{
        let service = DeviceDataService()
        let installationId = try await service.fireBaseId()
        
        let token = service.fireBaseToken
        let request: ProfileService.CreateOrUpdateDeviceInfoRequest = CreateOrUpdateDeviceInfoRequest(
            deviceId: installationId,
            deviceName: service.deviceId,
            fcmToken: token,
            platform: service.deviceName,
            operationSystem: service.operatingSystem,
            applicationVersion: service.applicationBuild
        )
        print(request)
        let response = try await self.client.post("profile/device/register", body: request)
        print(response)
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(DeviceRegisterResultResult.self,from:response.response)
    }
    
    func getDevices() async throws -> DeviceInfoDtoListResult{
        let response = try await self.client.get("profile/devices")
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(DeviceInfoDtoListResult.self,from:response.response)
    }
    
    func trust(_ deviceId: String) async throws -> DeviceInfoDtoResult{
        let response = try await self.client.patch("profile/device/\(deviceId)/trust")
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(DeviceInfoDtoResult.self,from:response.response)
    }
    
    func untrust(_ deviceId: String) async throws -> DeviceInfoDtoResult{
        let response = try await self.client.patch("profile/device/\(deviceId)/untrust")
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(DeviceInfoDtoResult.self,from:response.response)
    }
}
