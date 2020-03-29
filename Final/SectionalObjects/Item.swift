//
//  Item.swift
//  SectionalObjects
//

import CoreData
import Foundation

final class Item: NSManagedObject, ManagedObject {
    @NSManaged var name: String
    @NSManaged var selected: Bool

    @NSManaged var section: Section

    static var defaultSortDescriptors: [NSSortDescriptor] {
        [
            NSSortDescriptor(keyPath: \Item.selected, ascending: true),
            NSSortDescriptor(keyPath: \Item.name, ascending: true)
        ]
    }
}
