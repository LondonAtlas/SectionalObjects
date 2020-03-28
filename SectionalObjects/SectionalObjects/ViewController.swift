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

    lazy var fetchedResultsController: NSFetchedResultsController<Item> = {
        let request = Item.sortedFetchRequest
        request.relationshipKeyPathsForPrefetching = [#keyPath(Item.section)]
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.section.name, ascending: true),
            NSSortDescriptor(keyPath: \Item.selected, ascending: true),
            NSSortDescriptor(keyPath: \Item.name, ascending: true)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: #keyPath(Item.section.name),
            cacheName: nil
        )

        controller.delegate = self

        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        try? fetchedResultsController.performFetch()
    }

    // MARK: - TableView Delegate & DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = item.name

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        fetchedResultsController.sections?[section].name
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = fetchedResultsController.object(at: indexPath)
        item.selected.toggle()

        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = item.selected ? .checkmark : .none
    }
}

extension TableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {
        switch type {
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)

        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)

        case .update:
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)

        default:
            break
        }
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
            tableView.deleteRows(at: [indexPath!], with: .automatic)

        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)

        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)

        case .update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)

        @unknown default:
            break
        }
    }
}
