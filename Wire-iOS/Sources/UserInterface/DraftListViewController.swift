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


final class DraftListViewController: CoreDataTableViewController<MessageDraft, DraftMessageCell> {

    let persistence: MessageDraftStorage

    init(persistence: MessageDraftStorage) {
        self.persistence = persistence
        super.init(fetchedResultsController: persistence.resultsController)
        configureCell = { (cell, draft) in
            cell.configure(with: draft)
        }

        onCellSelection = { (_, draft) in
            self.showDraft(draft)
        }

        onDelete = { (_, draft) in
            persistence.enqueue(block: {
                $0.delete(draft)
            }, completion: {
                if self.splitViewController?.isCollapsed == false {
                    self.showDraft(nil)
                }
            })
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "compose.drafts.title".localized.uppercased()
        navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .X, style: .done, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(icon: .plus, target: self, action: #selector(newDraftTapped))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        DraftMessageCell.register(in: tableView)
        tableView.rowHeight = 60
    }

    private dynamic func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    private dynamic func newDraftTapped(_ sender: Any) {
        showDraft(nil)
    }

    fileprivate func showDraft(_ draft: MessageDraft?) {
        let composeViewController = MessageComposeViewController(draft: draft, persistence: persistence)
        composeViewController.delegate = splitViewController as? DraftsRootViewController
        let detail = DraftNavigationController(rootViewController: composeViewController)
        splitViewController?.showDetailViewController(detail, sender: nil)
    }
    
}

