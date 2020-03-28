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
}
