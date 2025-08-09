//
//  RoutingStack.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 21.03.2024.
//

import Foundation

struct RoutingStack {
    private var storage: [RoutingView] = []
    
    internal mutating func append(_ view: RoutingView){
        storage.append(view)
    }

    internal mutating func removeAll() {
        storage.removeAll()
    }

    public mutating func removeLast() {
        if storage.count > 0 { storage.removeLast() }
    }

    internal var last: RoutingView? { storage.last }

    public func checkTag(tag: String) -> Bool {
        getIndex(tag) == nil ? false : true
    }

    public mutating func move(tag: String, force: Bool = false) {
        let index = getIndex(tag)
        
        if index == nil && checkTag(tag: tag) || force {
            storage.append(storage.remove(at: index!))
        } else {
            removeLast()
        }
    }

    private func getIndex(_ tag: String) -> Int? {
        let cell = self.storage.firstIndex(where: { $0.id == tag })
        return cell
    }
}
