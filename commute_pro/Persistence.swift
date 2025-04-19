//
//  Persistence.swift
//  commute_pro
//
//  Created by Tony Pennoyer on 4/15/25.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<3 {
            let newCommute = Commute(context: viewContext)
            newCommute.name = "Sample Commute"
            newCommute.mode = "walk"
        }
        do {
            try result.save()
        } catch {
            print("Preview data creation failed: \(error)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "commute_pro")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                // Log the error but don't crash in production
                #if DEBUG
                print("Debug details: \(error)")
                #endif
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        setupValidationRules()
    }
    
    private func setupValidationRules() {
        // Add validation rules to the model
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up default values and constraints
        if let entity = NSEntityDescription.entity(forEntityName: "Commute", in: container.viewContext) {
            entity.properties.forEach { property in
                if let attribute = property as? NSAttributeDescription {
                    switch attribute.name {
                    case "name":
                        attribute.isOptional = false
                    case "mode":
                        attribute.isOptional = false
                        attribute.defaultValue = "walk"
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func save() throws {
        let context = container.viewContext
        
        // Validate before saving
        try validate()
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw CoreDataError.savingError(error)
            }
        }
    }
    
    private func validate() throws {
        let context = container.viewContext
        
        // Validate all objects in the context
        for object in context.insertedObjects.union(context.updatedObjects) {
            if let commute = object as? Commute {
                // Validate Commute
                if commute.name?.isEmpty ?? true {
                    throw CoreDataError.validationError("Commute name cannot be empty")
                }
                
                if let mode = commute.mode {
                    let validModes = ["walk", "bike", "run", "subway"]
                    if !validModes.contains(mode.lowercased()) {
                        throw CoreDataError.validationError("Invalid commute mode: \(mode)")
                    }
                }
            } else if let session = object as? Session {
                // Validate Session
                if session.duration < 0 {
                    throw CoreDataError.validationError("Session duration cannot be negative")
                }
                
                if session.date == nil {
                    session.date = Date()
                }
                
                if session.id == nil {
                    session.id = UUID()
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    
    func batchDelete(entityName: String, predicate: NSPredicate? = nil) throws {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        } catch {
            throw CoreDataError.savingError(error)
        }
    }
}

// MARK: - View Context Extension
extension NSManagedObjectContext {
    func safeSave() throws {
        if hasChanges {
            do {
                try save()
            } catch {
                // Rollback on error
                rollback()
                throw CoreDataError.savingError(error)
            }
        }
    }
}
