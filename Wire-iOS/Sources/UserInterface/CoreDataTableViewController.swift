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


class CoreDataTableViewController<Model: NSFetchRequestResult, Cell: UITableViewCell>: UITableViewController, NSFetchedResultsControllerDelegate {

    typealias TableViewAction = (Cell, Model) -> Void

    var configureCell: TableViewAction?
    var onCellSelection: TableViewAction?
    var onDelete: TableViewAction?

    let fetchedResultsController: NSFetchedResultsController<Model>

    init(fetchedResultsController: NSFetchedResultsController<Model>) {
        self.fetchedResultsController = fetchedResultsController
        super.init(nibName: nil, bundle: nil)
        self.fetchedResultsController.delegate = self
        Cell.register(in: tableView)
        try? fetchedResultsController.performFetch()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.zm_reuseIdentifier, for: indexPath) as! Cell
        configureCell?(cell, fetchedResultsController.object(at: indexPath))
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as! Cell
        onCellSelection?(cell, fetchedResultsController.object(at: indexPath))
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if nil != onDelete {
            return .delete
        }
        return .none
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = tableView.cellForRow(at: indexPath) as! Cell
            onDelete?(cell, fetchedResultsController.object(at: indexPath))
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
