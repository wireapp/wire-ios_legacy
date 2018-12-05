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
import WireExtensionComponents

/**
 * A view controller wrapping the message details.
 */

@objc class MessageDetailsViewController: UIViewController, ModalTopBarDelegate {

    /// The displayed message.
    let message: ZMConversationMessage

    /// The data source for the message details.
    let dataSource: MessageDetailsDataSource

    // MARK: - UI Elements

    let container: TabBarController
    let topBar = ModalTopBar()
    var reactionsViewController = MessageDetailsContentViewController(contentType: .reactions)
    var readReceiptsViewController = MessageDetailsContentViewController(contentType: .receipts(enabled: false))

    // MARK: - Initialization

    @objc init(message: ZMConversationMessage) {
        self.message = message
        self.dataSource = MessageDetailsDataSource(message: message)

        var viewControllers: [MessageDetailsContentViewController]

        // Setup the appropriate view controllers
        switch dataSource.displayMode {
        case .combined:
            reactionsViewController.conversation = dataSource.conversation
            readReceiptsViewController.conversation = dataSource.conversation
            readReceiptsViewController.contentType = .receipts(enabled: dataSource.receiptsSupported)
            viewControllers = [readReceiptsViewController, reactionsViewController]
        case .reactions:
            reactionsViewController.conversation = dataSource.conversation
            viewControllers = [reactionsViewController]
        case .receipts:
            readReceiptsViewController.conversation = dataSource.conversation
            readReceiptsViewController.contentType = .receipts(enabled: dataSource.receiptsSupported)
            viewControllers = [readReceiptsViewController]
        }

        container = TabBarController(viewControllers: viewControllers)

        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .formSheet
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.from(scheme: .barBackground)
        dataSource.observer = self

        // Configure the top bar
        view.addSubview(topBar)
        topBar.delegate = self
        topBar.needsSeparator = false
        topBar.configure(title: dataSource.title, subtitle: nil, topAnchor: safeTopAnchor)
        reloadFooters()

        // Configure the content
        addChild(container)
        view.addSubview(container.view)
        container.didMove(toParent: self)
        container.isTabBarHidden = dataSource.displayMode != .combined
        container.isEnabled = dataSource.displayMode == .combined

        // Create the constraints
        configureConstraints()

        // Display initial data
        reloadData()
        reloadPlaceholders()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .layoutChanged, argument: topBar)
    }

    private func configureConstraints() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        container.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // topBar
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // container
            container.view.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            container.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Data

    func reloadData() {
        switch dataSource.displayMode {
        case .combined:
            reactionsViewController.updateData(dataSource.reactions)
            readReceiptsViewController.updateData(self.dataSource.readReceipts)

        case .reactions:
            reactionsViewController.updateData(dataSource.reactions)
        case .receipts:
            readReceiptsViewController.updateData(self.dataSource.readReceipts)
        }
    }

    private func reloadFooters() {
        switch dataSource.displayMode {
        case .combined:
            reactionsViewController.subtitle = dataSource.subtitle
            reactionsViewController.accessibleSubtitle = dataSource.accessibilitySubtitle
            
            readReceiptsViewController.subtitle = dataSource.subtitle
            readReceiptsViewController.accessibleSubtitle = dataSource.accessibilitySubtitle

        case .reactions:
            reactionsViewController.subtitle = dataSource.subtitle
            reactionsViewController.accessibleSubtitle = dataSource.accessibilitySubtitle

        case .receipts:
            readReceiptsViewController.subtitle = dataSource.subtitle
            readReceiptsViewController.accessibleSubtitle = dataSource.accessibilitySubtitle
        }
    }

    private func reloadPlaceholders() {
        guard dataSource.displayMode.isOne(of: .receipts, .combined) else {
            return
        }

        readReceiptsViewController.contentType = .receipts(enabled: dataSource.receiptsSupported)
    }

    // MARK: - Top Bar

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true, completion: nil)
        return true
    }

    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - MessageDetailsDataSourceObserver

extension MessageDetailsViewController: MessageDetailsDataSourceObserver {

    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadData()
    }

    func detailsFooterDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadFooters()
    }

    func receiptsStatusDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadPlaceholders()
    }

}
