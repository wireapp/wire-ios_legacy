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


final class DraftListViewController: CoreDataTableViewController<MessageDraft, DraftMessageCell> {

    private let persistence: MessageDraftStorage
    private let emptyLabel = UILabel()

    init(persistence: MessageDraftStorage) {
        self.persistence = persistence
        super.init(fetchedResultsController: persistence.resultsController)
        setupEmptyLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configure(cell: DraftMessageCell, with model: MessageDraft) {
        cell.configure(with: model)
    }

    override func select(cell: DraftMessageCell, with model: MessageDraft) {
        showDraft(model)
    }

    override func emptyStateDidChange(isEmpty: Bool) {
        tableView.isHidden = isEmpty
        emptyLabel.isHidden = !isEmpty
    }

    override func delete(cell: DraftMessageCell, with model: MessageDraft) {
        persistence.enqueue(block: {
            $0.delete(model)
        }, completion: { [weak self] in
            if self?.splitViewController?.isCollapsed == false {
                self?.showDraft(nil)
            }
        })
    }

    private func setupEmptyLabel() {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 4
        let paragraphAttributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let color = UIColor.from(scheme: .textDimmed)
        let title = "compose.drafts.empty.title".localized.uppercased() && FontSpec(.small, .semibold).font!
        let subtitle = "compose.drafts.empty.subtitle".localized.uppercased() && FontSpec(.small, .light).font!
        emptyLabel.attributedText = (title + "\n" + subtitle) && color && paragraphAttributes
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)
        view.backgroundColor = UIColor.from(scheme: .background)

        constrain(view, emptyLabel) { view, emptyLabel in
            emptyLabel.centerY == view.centerY - 20
            emptyLabel.centerX == view.centerX
            emptyLabel.width <= 200
            emptyLabel.leading >= view.leading + 24
            emptyLabel.trailing <= view.trailing - 20
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        title = "compose.drafts.title".localized.uppercased()
        tableView.backgroundColor = UIColor.from(scheme: .background)
        navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .X, style: .done, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "closeButton"
        navigationItem.leftBarButtonItem = UIBarButtonItem(icon: .plus, target: self, action: #selector(newDraftTapped))
        navigationItem.leftBarButtonItem?.accessibilityLabel = "newDraftButton"
        DraftMessageCell.register(in: tableView)
        tableView.rowHeight = 64
        tableView.separatorStyle = .none
    }

    @objc  func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func newDraftTapped(_ sender: Any) {
        showDraft(nil)
    }

    fileprivate func showDraft(_ draft: MessageDraft?) {
        let composeViewController = MessageComposeViewController(draft: draft, persistence: persistence)
        composeViewController.delegate = splitViewController as? DraftsRootViewController
        let detail = DraftNavigationController(rootViewController: composeViewController)
        splitViewController?.showDetailViewController(detail, sender: nil)
    }
    
}

