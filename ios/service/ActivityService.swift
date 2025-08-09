//
//  ActivityService.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 20.05.2024.
//

import Foundation
import SwiftUI
import Combine

class ActivityService: NSObject {
    private typealias SendEventFunc = @convention(c) (AnyObject, Selector, UIEvent) -> Void
    
    @objc func mySendEvent(_ event: UIEvent) {
        // call the original sendEvent
        // from: https://stackoverflow.com/a/61523711/5133585
        unsafeBitCast(
            class_getMethodImplementation(ActivityService.self, #selector(mySendEvent)),
            to: SendEventFunc.self
        )(self, #selector(UIApplication.sendEvent), event)

        // send a notification, just like in the non-SwiftUI solutions
        NotificationCenter.default.post(name: .Activity, object: nil)
    }
}

class ApplicationActivityController: ObservableObject{
    private var subscriptions = Set<AnyCancellable>()
    private var lastActivityTs = NSDate().timeIntervalSince1970
    private var task: DispatchWorkItem? = nil
    
    /// Register user activity
    func registerActivity(){
        self.lastActivityTs = NSDate().timeIntervalSince1970
        
        self.task?.cancel()
        self.task = nil
        
        self.task = DispatchWorkItem{
            NotificationCenter.default.post(name: .Inactive, object: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (60*5), execute: self.task!)
    }
}
