//
//  AppDelegate.swift
//  SectionalObjects
//

import UIKit
import CoreData

struct DummyData {
    let content = [
        "Section 1": [
            "Item 1",
            "Item 2",
            "Item 3",
            "Item 4",
            "Item 5"
        ],
        "Section 2": [
            "Item 1",
            "Item 2"
        ],
        "Section 3": [
            "Item 1",
            "Item 2",
            "Item 3"
        ],
        "Section 4": [],
        "Section 5": []
    ]
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let hasDemoContent = UserDefaults.standard.bool(forKey: "demo")
        if hasDemoContent == false {
            let context = persistentContainer.newBackgroundContext()

            context.performChangesAndWait {
                let dummyData = DummyData()

                dummyData.content.keys.forEach { sectionName in
                    let section: Section = context.insertObject()
                    section.name = sectionName
                    dummyData.content[sectionName]?.forEach { value in
                        let item: Item = context.insertObject()
                        item.name = value
                        item.section = section
                    }
                }
            }

            UserDefaults.standard.set(true, forKey: "demo")
            UserDefaults.standard.synchronize()
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SectionalObjects")
        let semaphore = DispatchSemaphore(value: container.persistentStoreDescriptions.count)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            semaphore.signal()
        })

        guard semaphore.wait(timeout: .now() + 30) == .success else {
            fatalError("blahhhhhhhhh")
        }

        
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

