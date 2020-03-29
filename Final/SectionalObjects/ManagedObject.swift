//
//  ManagedObject.swift
//  SectionalObjects
//

import CoreData
import Foundation

public protocol ManagedObjectEntity: class, NSFetchRequestResult {
    static var entityName: String { get }
    static var entity: NSEntityDescription { get }
}

public protocol ManagedObject: ManagedObjectEntity {
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    static var defaultPredicate: NSPredicate { get }
    var managedObjectContext: NSManagedObjectContext? { get }
}

extension ManagedObject {
    public static var defaultSortDescriptors: [NSSortDescriptor] { return [] }
    public static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }

    public static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        request.sortDescriptors = Self.defaultSortDescriptors
        request.predicate = Self.defaultPredicate
        return request
    }

    public static func sortedFetchRequest(with predicate: NSPredicate) -> NSFetchRequest<Self> {
        let request = Self.sortedFetchRequest
        guard let existingPredicate = request.predicate else { fatalError("must have predicate") }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existingPredicate, predicate])
        return request
    }

    public static func predicate(format: String, _ args: CVarArg...) -> NSPredicate {
        let predicate = withVaList(args) { NSPredicate(format: format, arguments: $0) }
        return self.predicate(predicate)
    }

    public static func predicate(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [Self.defaultPredicate, predicate])
    }
}

extension ManagedObjectEntity where Self: NSManagedObject {
    public static var entityName: String {
        return Self.entity.name!
    }

    public static var entity: NSEntityDescription { return entity() }
}

extension ManagedObject where Self: NSManagedObject {
    public static func findOrCreate(in context: NSManagedObjectContext,
                             matching predicate: NSPredicate,
                             configure: ((Self) -> Void)? = nil) -> Self {
        let configureBlock: (Self) -> Void = configure ?? { _ in }

        return self.findOrCreate(in: context, matching: predicate, configure: configureBlock)
    }

    public static func findOrCreate(in context: NSManagedObjectContext,
                             matching predicate: NSPredicate,
                             configure: (Self) -> Void) -> Self {
        guard let object = Self.findOrFetch(in: context, matching: predicate) else {
            let newObject: Self = context.insertObject()
            configure(newObject)
            return newObject
        }
        return object
    }

    public static func findOrFetch(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        guard let object = self.materializedObject(in: context, matching: predicate) else {
            return Self.fetch(in: context) { request in
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
            }.first
        }
        return object
    }

    public static func fetch(in context: NSManagedObjectContext,
                      configurationBlock: (NSFetchRequest<Self>) -> Void = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try! context.fetch(request)
    }

    public static func count(in context: NSManagedObjectContext, configure: (NSFetchRequest<Self>) -> Void = { _ in }) -> Int {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configure(request)
        return try! context.count(for: request)
    }

    static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self, predicate.evaluate(with: result) else { continue }
            return result
        }
        return nil
    }
}

extension ManagedObject where Self: NSManagedObject {
    fileprivate static func fetchSingleObject(in context: NSManagedObjectContext,
                                              configure: (NSFetchRequest<Self>) -> Void) -> Self? {
        let result = Self.fetch(in: context) { request in
            configure(request)
            request.fetchLimit = 2
        }
        switch result.count {
        case 0: return nil
        case 1: return result[0]
        default: fatalError("Returned multiple objects, expected max 1")
        }
    }

    public func revertChanges() {
        let changes = self.changedValues()
        let keys = changes.map { $0.key }
        let commitedValues = self.committedValues(forKeys: keys)
        for (key, _) in changes {
            self.setValue(commitedValues[key], forKey: key)
        }
    }
}

extension NSManagedObjectContext {
    public func delete<A: Sequence>(_ objects: A) where A.Element: NSManagedObject {
        for object in objects {
            self.delete(object)
        }
    }

    public func insertObject<A: NSManagedObject>() -> A where A: ManagedObject {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else {
                 fatalError("Wrong object type")
        }
        return obj
    }

    func saveOrRollback() -> Bool {
        guard self.hasChanges else { return true }

        do {
            try self.save()
            return true
        } catch {
            self.rollback()
            return false
        }
    }

    func performSaveOrRollback() {
        self.perform {
            _ = self.saveOrRollback()
        }
    }

    func performChanges(block: @escaping () -> Void) {
        self.perform {
            block()
            _ = self.saveOrRollback()
        }
    }

    func performSaveOrRollbackAndWait() {
        self.performAndWait {
            _ = self.saveOrRollback()
        }
    }

    public func performChangesAndWait(block: @escaping () -> Void) {
        self.performAndWait {
            block()
            _ = self.saveOrRollback()
        }
    }
}

