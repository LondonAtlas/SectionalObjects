//
//  ViewController.swift
//  SectionalObjects
//

import CoreData
import UIKit

final class TableViewController: UITableViewController {
    var viewContext: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController<Section> = {
        let request = Section.sortedFetchRequest
        request.relationshipKeyPathsForPrefetching = [#keyPath(Section.items)]
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Section.name, ascending: true)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        controller.delegate = self

        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        try? fetchedResultsController.performFetch()

        navigationItem.leftBarButtonItem = editButtonItem
    }

    private func items(for section: Section) -> [Item] {
        Item.fetch(in: viewContext) { request in
            request.sortDescriptors = Item.defaultSortDescriptors
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(Item.section), section)
        }
    }
}

// MARK: - TableView DataSource
extension TableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionObject = fetchedResultsController.fetchedObjects?[section] else {
            return 0
        }

        return items(for: sectionObject).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let section = fetchedResultsController.fetchedObjects?[indexPath.section] else {
            fatalError("")
        }
        let item = items(for: section)[indexPath.row]

        cell.textLabel?.text = item.name
        cell.accessoryType = item.selected ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        fetchedResultsController.fetchedObjects?[section].name
    }
}

// MARK: - TableView Delegate
extension TableViewController {
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        guard let section = fetchedResultsController.fetchedObjects?[indexPath.section] else { return }
        let item = items(for: section)[indexPath.row]

        viewContext.delete(item)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = fetchedResultsController.fetchedObjects?[indexPath.section] else {
            fatalError("Section does not exist at indexPath: \(indexPath)")
        }
        let item = items(for: section)[indexPath.row]

        item.selected.toggle()

        tableView.cellForRow(at: indexPath)?.accessoryType = item.selected ? .checkmark : .none

        let newRow = items(for: section).firstIndex(of: item)!
        let newIndexPath = IndexPath(row: newRow, section: indexPath.section)
        tableView.moveRow(at: indexPath, to: newIndexPath)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let sourceSection = fetchedResultsController.fetchedObjects?[sourceIndexPath.section],
            let destinationSection = fetchedResultsController.fetchedObjects?[destinationIndexPath.section] else {
                return
        }

        let item = items(for: sourceSection)[sourceIndexPath.row]
        item.section = destinationSection
    }
}

extension TableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .delete:
            tableView.deleteSections(IndexSet(integer: indexPath!.row), with: .automatic)

        case .insert:
            tableView.insertSections(IndexSet(integer: newIndexPath!.row), with: .automatic)

        case .move:
            break

        case .update:
            tableView.reloadSections(IndexSet(integer: indexPath!.row), with: .automatic)

        @unknown default:
            break
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         tableView.beginUpdates()
     }
}
