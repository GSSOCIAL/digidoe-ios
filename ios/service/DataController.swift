//
//  DataController.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.11.2024.
//

import Foundation
import CoreData

class DataController: ObservableObject{
    let container = NSPersistentContainer(name: "Store")
    
    init(){
        container.loadPersistentStores{ description, error in
            if let error = error {
                print("[CORE DATA] –", "Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
    }
    
    public func clearDatabase() async throws{
        
        guard let url = self.container.persistentStoreDescriptions.first?.url else { return }
        
        let persistentStoreCoordinator = self.container.persistentStoreCoordinator
        self.container.viewContext.reset()
        
        try persistentStoreCoordinator.destroyPersistentStore(at:url, ofType: NSSQLiteStoreType, options: nil)
        
        self.container.loadPersistentStores{ description, error in
            if let error = error {
                print("[CORE DATA] –", "Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
    }
}
