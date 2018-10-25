//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//


import Foundation
import Cartography


class CoreDataTableViewController<Model: NSFetchRequestResult, Cell: UITableViewCell>: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    let tableView = UITableView(frame: .zero, style: .plain)
    var canDelete = true

    let fetchedResultsController: NSFetchedResultsController<Model>

    init(fetchedResultsController: NSFetchedResultsController<Model>) {
        self.fetchedResultsController = fetchedResultsController
        super.init(nibName: nil, bundle: nil)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        constrain(view, tableView) { view, tableView in tableView.edges == view.edges }
        fetchedResultsController.delegate = self
        Cell.register(in: tableView)
        try? fetchedResultsController.performFetch()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(cell: Cell, with model: Model) {
        preconditionFailure("Subclasses must override this method")
    }

    func select(cell: Cell, with model: Model) {
        // no-op
    }

    func delete(cell: Cell, with model: Model) {
        // no-op
    }

    func emptyStateDidChange(isEmpty: Bool) {
        // no-op
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = fetchedResultsController.sections?[section].numberOfObjects ?? 0
        emptyStateDidChange(isEmpty: numberOfRows == 0)
        return numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.zm_reuseIdentifier, for: indexPath) as! Cell
        configure(cell: cell, with: fetchedResultsController.object(at: indexPath))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as! Cell
        select(cell: cell, with: fetchedResultsController.object(at: indexPath))
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return canDelete ? .delete : .none
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! Cell
            delete(cell: cell, with: fetchedResultsController.object(at: indexPath))
        }
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            if let insertIndexPath = newIndexPath {
                tableView.insertRows(at: [insertIndexPath], with: .automatic)
            }
        case .delete:
            if let deleteIndexPath = indexPath {
                tableView.deleteRows(at: [deleteIndexPath], with: .automatic)
            }
        case .update:
            if let updateIndexPath = indexPath {
                tableView.reloadRows(at:  [updateIndexPath], with: .automatic)
            }
        case .move:
            if let deleteIndexPath = indexPath {
                tableView.deleteRows(at: [deleteIndexPath], with: .automatic)
            }
            if let insertIndexPath = newIndexPath {
                tableView.insertRows(at: [insertIndexPath], with: .automatic)
            }
        }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType) {

        switch type {
        case .insert: tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete: tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default: break
        }
    }

}
