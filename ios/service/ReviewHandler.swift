//
//  ReviewHandler.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 23.12.2023.
//

import Foundation
import StoreKit
import SwiftUI

class ReviewHandler {
    
    static func requestReview() {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
