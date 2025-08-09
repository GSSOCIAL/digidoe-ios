//
//  RoutingView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 21.03.2024.
//

import Foundation
import SwiftUI

struct RoutingView: Equatable, Identifiable {
    public let id: String
    public let view: AnyView
    
    init(_ id: String, _ view: AnyView){
        self.id = id
        self.view = view
    }
    public static func == (lhs: RoutingView, rhs: RoutingView) -> Bool {
        lhs.id == rhs.id
    }
}
