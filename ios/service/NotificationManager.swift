//
//  NotificationManager.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.02.2024.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate{
    @Published private(set) var hasPermission = false
    
    func requestAuthorization() async{
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await getAuthStatus()
        } catch{
            await getAuthStatus()
        }
    }
    
    func getAuthStatus() async -> Bool{
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            self.hasPermission = true
            return true
        default:
            self.hasPermission = false
        }
        return false
    }
}

public class NotificationHandler: ObservableObject{
    public static let shared = NotificationHandler()
    
    @Published private(set) var notification: PushNotification? = nil
    @Published private(set) var received: PushNotification? = nil
    
    // MARK: - Methods
    /// Handles the receiving of a UNNotificationResponse and propagates it to the app
    ///
    /// - Parameters:
    ///   - notification: The UNNotificationResponse to handle
    func handle(notification: PushNotification?) {
        self.notification = notification
    }
    
    /// Receive app notification
    ///
    /// - Parameters:
    ///   - notification: The UNNotificationResponse to handle
    func receive(notification: PushNotification?) {
        self.received = notification
    }
}
