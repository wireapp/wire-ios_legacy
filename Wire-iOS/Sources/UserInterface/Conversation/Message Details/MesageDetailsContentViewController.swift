//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit

/**
 * Displays the list of users for a specified message detail content type.
 */

class MesageDetailsContentViewController: UIViewController {

    /// The type of the displayed content.
    enum ContentType {
        case reactions, receipts(enabled: Bool)
    }

    // MARK: - Configuration

    /// The conversation that is being accessed.
    var conversation: ZMConversation!

    /// The type of the displayed content.
    var contentType: ContentType {
        didSet {
            configureForContentType()
        }
    }

    /// The subtitle displaying message details.
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
            collectionView.map(updateFooterPosition)
        }
    }

    /// The displayed cells.
    fileprivate(set) var cells: [MessageDetailsCellDescription] = []

    // MARK: - UI Elements

    fileprivate let noResultsView = NoResultsView()
    fileprivate var collectionView: UICollectionView!
    fileprivate var subtitleLabel = UILabel()
    fileprivate var subtitleBottom: NSLayoutConstraint?

    // MARK: - Initialization

    /**
     * Creates a view controller to display message details of a certain type.
     */

    init(contentType: ContentType) {
        self.contentType = contentType
        super.init(nibName: nil, bundle: nil)
        updateTitle()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }

    private func configureSubviews() {
        view.backgroundColor = .from(scheme: .contentBackground)

        collectionView = UICollectionView(forUserList: ())
        collectionView.contentInset.bottom = 64
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        UserCell.register(in: collectionView)
        view.addSubview(collectionView)

        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = .mediumFont
        subtitleLabel.textColor = UIColor.from(scheme: .sectionText)
        subtitleLabel.accessibilityLabel = "DeliveryStatus"
        view.addSubview(subtitleLabel)

        noResultsView.isHidden = true
        configureForContentType()
        view.addSubview(noResultsView)
        updateData(cells)
        configureConstraints()
    }

    private func updateTitle() {
        switch contentType {
        case .receipts:
            title = "message_details.tabs.seen".localized(args: cells.count).uppercased()
        case .reactions:
            title = "message_details.tabs.likes".localized(args: cells.count).uppercased()
        }
    }

    private func updateFooterPosition(for scrollView: UIScrollView) {
        let padding: CGFloat = 8
        let footerHeight = subtitleLabel.frame.height.rounded(.up)
        let footerRegionHeight = 28 + footerHeight + padding

        guard !cells.isEmpty else {
            subtitleBottom?.constant = -padding
            return
        }

        // Update the bottom cell padding to fit the text
        collectionView.contentInset.bottom = footerRegionHeight

        /*
         We calculate the distance between the bottom of the last cell and the bottom of the view.

         We use this height to move the status label offscreen if needed, and move it up alongside the
         content if the user scroll up.
         */

        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        let scrollableContentHeight = scrollView.contentInset.top + scrollView.contentSize.height + footerRegionHeight
        let visibleOnScreen = min(scrollableContentHeight - offset, scrollView.bounds.height - scrollView.contentInset.top)
        let bottomSpace = scrollableContentHeight - (visibleOnScreen + offset)

        let constant = bottomSpace - padding
        subtitleBottom?.constant = constant
    }

    private func configureForContentType() {
        switch contentType {
        case .reactions:
            noResultsView.label.accessibilityLabel = "no likes"
            noResultsView.label.text = "message_details.empty_likes".localized.uppercased()
            noResultsView.icon = .like

        case .receipts(enabled: true):
            noResultsView.label.accessibilityLabel = "no read receipts"
            noResultsView.label.text = "message_details.empty_read_receipts".localized.uppercased()
            noResultsView.icon = .eye

        case .receipts(enabled: false):
            noResultsView.label.accessibilityLabel = "read receipts disabled"
            noResultsView.label.text = "message_details.read_receipts_disabled".localized.uppercased()
            noResultsView.icon = .eye
        }
    }

    private func configureConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        noResultsView.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        collectionView.fitInSuperview()
        subtitleBottom = subtitleLabel.bottomAnchor.constraint(equalTo: safeBottomAnchor)
        subtitleBottom!.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // noResultsView
            noResultsView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 12),
            noResultsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -44),
            noResultsView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
            noResultsView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            noResultsView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            // subtitleLabel
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleBottom!
        ])
    }

    // MARK: - Updating the Data

    /**
     * Updates the list of users for the details.
     * - parameter cells: The new list of cells to display.
     */

    func updateData(_ cells: [MessageDetailsCellDescription]) {
        noResultsView.isHidden = !cells.isEmpty

        // If the collection view doesn't exit, set the initial data and return
        guard let collectionView = self.collectionView else {
            self.cells = cells
            return updateTitle()
        }

        let old = self.cells
        let new = cells

        let updates = {
            self.cells = new

            let old = ZMOrderedSetState(orderedSet: NSOrderedSet(array: old))
            let new = ZMOrderedSetState(orderedSet: NSOrderedSet(array: new))
            let change = ZMChangedIndexes(start: old, end: new, updatedState: new, moveType: .uiCollectionView)

            if let deleted = change?.deletedIndexes.indexPaths(in: 0) {
                collectionView.deleteItems(at: deleted)
            }

            if let inserted = change?.insertedIndexes.indexPaths(in: 0) {
                collectionView.insertItems(at: inserted)
            }

            change?.enumerateMovedIndexes { (oldIndex, newIndex) in
                let oldIndexPath = IndexPath(item: Int(oldIndex), section: 0)
                let newIndexPath = IndexPath(item: Int(newIndex), section: 0)
                collectionView.moveItem(at: oldIndexPath, to: newIndexPath)
            }
        }

        collectionView.performBatchUpdates(updates) { finished in
            if finished {
                self.updateTitle()
                self.updateFooterPosition(for: collectionView)
            }
        }
    }

}

// MARK: - UICollectionViewDataSource

extension MesageDetailsContentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cells.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let description = cells[indexPath.item]
        let cell = collectionView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)

        cell.configure(with: description.user, subtitle: description.attributedTitle, conversation: conversation)
        cell.showSeparator = indexPath.item != (cells.endIndex - 1)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    /// When the user selects a cell, show the details for this user.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = cells[indexPath.item].user
        let cell = collectionView.cellForItem(at: indexPath) as! UserCell

        let profileViewController = ProfileViewController(user: user, conversation: conversation)
        profileViewController.delegate = self
        profileViewController.viewControllerDismisser = self

        presentDetailsViewController(profileViewController, above: cell)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateFooterPosition(for: scrollView)
    }

}

// MARK: - ProfileViewControllerDelegate

extension MesageDetailsContentViewController: ProfileViewControllerDelegate, ViewControllerDismisser {

    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared()?.load(conversation, scrollTo: nil, focusOnView: true, animated: true)
        }
    }

}

// MARK: - Adaptive Presentation

extension MesageDetailsContentViewController {

    /// Presents a profile view controller as a popover or a modal depending on the context.
    fileprivate func presentDetailsViewController(_ controller: ProfileViewController, above cell: UserCell) {
        let presentedController = controller.wrapInNavigationController()
        presentedController.modalPresentationStyle = .popover

        if let popover = presentedController.popoverPresentationController {
            popover.sourceRect = cell.avatar.bounds
            popover.sourceView = cell.avatar
            popover.backgroundColor = .white
        }

        present(presentedController, animated: true)
    }

}
