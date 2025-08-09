//
//  RouterController.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 21.03.2024.
//

import Foundation
import SwiftUI

/**
 Declare home page
 */
protocol MainRouter {}

protocol RouterPage {
    var Router: RoutingController { get }
}

extension RoutingController{
    public enum RoutingType {
        case forward
        case backward
    }
    
    public enum RoutingTransition {
        case single(AnyTransition)
        case double(AnyTransition, AnyTransition)
        case none
        case `default`
        
        public static var transitions: (backward: AnyTransition, forward: AnyTransition) {
            (
                AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)),
                AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            )
        }
    }
}

public final class RoutingController: ObservableObject{
    var stack: RoutingStack {
        didSet {
            withAnimation(self.easing) {
                self.current = self.stack.last
            }
        }
    }
    
    private let easing: Animation
    private(set) var routingType: RoutingController.RoutingType
    
    @Published internal var current: RoutingView?
    
    public init(_ easing: Animation){
        self.stack = RoutingStack()
        self.easing = easing
        self.routingType = .forward
    }
    
    public func home(routingType: RoutingController.RoutingType = .backward){
        self.routingType = routingType
        self.stack.removeAll()
    }

    public func back(routingType: RoutingController.RoutingType = .backward){
        self.routingType = routingType
        self.stack.removeLast()
    }

    public func goTo<Element: View>(_ element: Element, tag: String = UUID().uuidString, routingType: RoutingController.RoutingType = .forward)
    {
        self.routingType = routingType
        if element is MainRouter { self.home() }
        stack.append(RoutingView(tag, AnyView(element)))
    }

    public func goTo(toTag tag: String, routingType: RoutingType = .backward, force: Bool = false){
        self.stack.move(tag: tag, force: force)
    }
}
