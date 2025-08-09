//
//  DigiDoe_FinVueApp.swift
//  DigiDoe FinVue
//
//  Created by Михайло Картмазов on 08.08.2025.
//

import UIKit
import SwiftUI
import UserNotifications

import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    @Published var notificationType: PushNotificationType? = nil
    @Published var notification: PushNotification? = nil
    
    var window: UIWindow?
    let gcmMessageIDKey: String = "gsm.Message_ID"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        //MARK: Request notifications
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in }
        )
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    ///Methods for C++ compiler
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (Int) -> Void) {
        let userInfo = notification.request.content.userInfo
        let type = userInfo["operation_type"] as? String
        print("[NOTIFICATION C++][RECEIVED] -", type)
        // Change this to your preferred presentation option
        let notification = obtainNotification(dictionary: userInfo)
        if (notification != nil){
            NotificationHandler.shared.receive(notification: notification)
        }
      if #available(iOS 14.0, *) {
        completionHandler(Int(UNNotificationPresentationOptions.banner.rawValue))
      } else {
        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
      }
    }

    /*
     Handle receive notifications
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        let type = userInfo["operation_type"] as? String
        print("[NOTIFICATION][RECEIVED] -", type)
        // Change this to your preferred presentation option
        let notification = obtainNotification(dictionary: userInfo)
        if (notification != nil){
            NotificationHandler.shared.receive(notification: notification)
        }
        return [[.alert, .sound]]
    }
    
    /**
     Handle notification touch
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        //Try to fetch in-app-notification
        let notification = obtainNotification(dictionary: userInfo)
        if (notification != nil){
            print("[NOTIFICATION][TOUCH]   -", notification?.type)
            self.notification = notification
            NotificationHandler.shared.handle(notification: notification)
        }
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        print("[FCM][MESSAGE]   -","Notification handle")
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        return UIBackgroundFetchResult.newData
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
    }
}

extension AppDelegate: MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            print("[FIREBASE][TOKEN]    -",fcm)
        }
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}

@main
struct EntryPoint {
    static func main() {
        let original = class_getInstanceMethod(UIApplication.self, #selector(UIApplication.sendEvent))!
        let new = class_getInstanceMethod(ActivityService.self, #selector(ActivityService.mySendEvent))!
        method_exchangeImplementations(original, new)

        DigiDoe_Business_BankingApp.main()
    }
}

struct DigiDoe_Business_BankingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var Error = ErrorHandlingService()
    @StateObject private var Router: RoutingController = RoutingController(Animation.interactiveSpring(duration:0.4))
    @StateObject private var Store = ApplicationStore()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var NotificationHandler: NotificationHandler = .shared
    @StateObject private var identity = AuthenticationService()
    @StateObject private var activityController = ApplicationActivityController()
    @StateObject private var maintenanceController = MaintenanceController()
    @StateObject private var scheduler = SchedulerController()
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.Error)
                .environmentObject(self.Router)
                .environmentObject(self.Store)
                .environmentObject(self.notificationManager)
                .environmentObject(self.NotificationHandler)
                .environmentObject(self.identity)
                .environmentObject(self.activityController)
                .environmentObject(self.maintenanceController)
                .environmentObject(self.scheduler)
                .environmentObject(self.dataController)
                .environment(\.managedObjectContext, self.dataController.container.viewContext)
                .onAppear{
                    self.activityController.registerActivity()
                }
                .onReceive(self.NotificationHandler.$notification, perform: { notification in
                    if (notification != nil){
                        self.Store.notification = notification
                        self.NotificationHandler.handle(notification: nil)
                    }
                })
                .onReceive(self.NotificationHandler.$received, perform: { notification in
                    if (notification != nil){
                        self.Store.receivedNotification = notification
                        self.NotificationHandler.receive(notification: nil)
                    }
                })
                .onOpenURL{ url in
                    if url.host == Enviroment.universalLinkHostForRegister{
                        //MARK: Deeplink login
                        Task{
                            do{
                                try await self.Store.logout()
                            }
                            NotificationCenter.default.post(name: .DeepLinkLogin, object: nil, userInfo: [
                                "url": url
                            ])
                        }
                    }
                }
        }
    }
}
