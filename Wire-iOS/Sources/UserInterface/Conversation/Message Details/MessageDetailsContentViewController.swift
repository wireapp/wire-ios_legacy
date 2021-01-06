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
import WireDataModel

/**
 * Displays the list of users for a specified message detail content type.
 */

final class MessageDetailsContentViewController: UIViewController {

    /// The type of the displayed content.
    enum ContentType {
        case reactions, receipts(enabled: Bool)
    }

    // MARK: - Configuration

    /// The conversation that is being accessed.
    let conversation: ZMConversation

    /// The type of the displayed content.
    let contentType: ContentType

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

    /// The subtitle displaying message details in Voice Over.
    var accessibleSubtitle: String? {
        get {
            return subtitleLabel.accessibilityValue
        }
        set {
            subtitleLabel.accessibilityValue = newValue
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

    init(contentType: ContentType, conversation: ZMConversation) {
        self.contentType = contentType
        self.conversation = conversation
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.map(updateFooterPosition)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    private func configureSubviews() {
        view.backgroundColor = .from(scheme: .contentBackground)

        collectionView = UICollectionView(forGroupedSections: ())
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
        subtitleLabel.accessibilityIdentifier = "DeliveryStatus"
        subtitleLabel.accessibilityLabel = "message_details.subtitle_label_voiceOver".localized
        view.addSubview(subtitleLabel)

        noResultsView.isHidden = true
        configureForContentType()
        view.addSubview(noResultsView)
        updateData(cells)
        configureConstraints()
        updateFooterPosition(for: collectionView)
    }

    private func updateTitle() {
        switch contentType {
        case .receipts:
            if cells.isEmpty {
                title = "message_details.receipts_title".localized(uppercased: true)
            } else {
                title = "message_details.tabs.seen".localized(args: cells.count).localizedUppercase
            }

        case .reactions:
            if cells.isEmpty {
                title = "message_details.likes_title".localized(uppercased: true)
            } else {
                title = "message_details.tabs.likes".localized(args: cells.count).localizedUppercase
            }
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
            noResultsView.label.accessibilityIdentifier = "placeholder.no_likes"
            noResultsView.placeholderText = "message_details.empty_likes".localized(uppercased: true)
            noResultsView.icon = .like

        case .receipts(enabled: true):
            noResultsView.label.accessibilityIdentifier = "placeholder.no_read_receipts"
            noResultsView.placeholderText = "message_details.empty_read_receipts".localized(uppercased: true)
            noResultsView.icon = .eye

        case .receipts(enabled: false):
            noResultsView.label.accessibilityIdentifier = "placeholder.read_receipts_disabled"
            noResultsView.placeholderText = "message_details.read_receipts_disabled".localized(uppercased: true)
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
        self.cells = cells
        self.updateTitle()

        guard let collectionView = self.collectionView else {
            return
        }

        collectionView.reloadData()
        self.updateFooterPosition(for: collectionView)
    }

}

// MARK: - UICollectionViewDataSource

extension MessageDetailsContentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cells.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let description = cells[indexPath.item]
        let cell = collectionView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)

        cell.configure(with: description.user, selfUser: ZMUser.selfUser(), subtitle: description.attributedSubtitle, conversation: conversation)
        cell.showSeparator = indexPath.item != (cells.endIndex - 1)
        cell.subtitleLabel.accessibilityLabel = description.accessibleSubtitleLabel
        cell.subtitleLabel.accessibilityValue = description.accessibleSubtitleValue

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    /// When the user selects a cell, show the details for this user.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = cells[indexPath.item].user
        let cell = collectionView.cellForItem(at: indexPath) as! UserCell

        let profileViewController = ProfileViewController(user: user, viewer: SelfUser.current, conversation: conversation)
        profileViewController.delegate = self
        profileViewController.viewControllerDismisser = self

        presentDetailsViewController(profileViewController, above: cell)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateFooterPosition(for: scrollView)
    }

}

extension MessageDetailsContentViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> ())?) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - ProfileViewControllerDelegate

extension MessageDetailsContentViewController: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared?.load(conversation, scrollTo: nil, focusOnView: true, animated: true)
        }
    }

    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: UserSet) {
        //no-op
    }
}

// MARK: - Adaptive Presentation

extension MessageDetailsContentViewController {

    /// Presents a profile view controller as a popover or a modal depending on the context.
    fileprivate func presentDetailsViewController(_ controller: ProfileViewController, above cell: UserCell) {
        let presentedController = controller.wrapInNavigationController()
        presentedController.modalPresentationStyle = .formSheet

        if let popover = presentedController.popoverPresentationController {
            popover.sourceRect = cell.avatar.bounds
            popover.sourceView = cell.avatar
            popover.backgroundColor = .white
        }

        present(presentedController, animated: true)
    }

}
