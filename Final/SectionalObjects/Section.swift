//
//  Section.swift
//  SectionalObjects
//

import CoreData
import Foundation

final class Section: NSManagedObject, ManagedObject {
    @NSManaged var name: String
    
    @NSManaged var items: Set<Item>
}
