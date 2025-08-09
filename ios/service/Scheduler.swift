//
//  Scheduler.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 23.05.2024.
//

import Foundation
import Combine

class SchedulerController: ObservableObject{
    private var subscriptions = Set<AnyCancellable>()
    private var fns: [Triggers:Array<(Triggers)->Void>] = [:]
    
    enum Triggers:Hashable{
        case APP_TOGGLE_ACTIVE
        case LOGIN(userId: String)
        case USER_CHANGED
        case NOTIFICATION_RECEIVED
        case APP_ENTRY
    }
}
