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
    var reactionsViewController = MesageDetailsContentViewController(contentType: .reactions)
    var readReceiptsViewController = MesageDetailsContentViewController(contentType: .receipts)

    // MARK: - Initialization

    @objc init(message: ZMConversationMessage) {
        self.message = message
        self.dataSource = MessageDetailsDataSource(message: message)

        var viewControllers: [UIViewController]

        // Setup the appropriate view controllers
        switch dataSource.displayMode {
        case .combined:
            viewControllers = [readReceiptsViewController, reactionsViewController]
        case .reactions:
            viewControllers = [reactionsViewController]
        case .receipts:
            viewControllers = [readReceiptsViewController]
        }

        container = TabBarController(viewControllers: viewControllers)

        super.init(nibName: nil, bundle: nil)
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
        configureTopBar()

        // Configure the content
        addChild(container)
        view.addSubview(container.view)
        container.didMove(toParent: self)
        container.isTabBarHidden = dataSource.displayMode != .combined
        container.isEnabled = dataSource.displayMode == .combined
        topBar.needsSeparator = dataSource.displayMode != .combined

        // Create the constraints
        configureConstraints()

        // Display initial data
        reloadData()
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

    private func configureTopBar() {
        topBar.configure(title: dataSource.title, subtitle: dataSource.subtitle, topAnchor: safeTopAnchor)
    }

    private func reloadData() {
        switch dataSource.displayMode {
        case .combined:
            reactionsViewController.cells = makeReactionCells()
            readReceiptsViewController.cells = makeReceiptsCell()
        case .reactions:
            reactionsViewController.cells = makeReactionCells()
        case .receipts:
            readReceiptsViewController.cells = makeReceiptsCell()
        }
    }

    private func makeReactionCells() -> [MessageDetailsCellDescription] {
        return dataSource.reactions.map { user in
            let handle = user.handle.map { "@" + $0 }
            return MessageDetailsCellDescription(user: user, subtitle: handle)
        }
    }

    private func makeReceiptsCell() -> [MessageDetailsCellDescription] {
        return dataSource.readReciepts.map { user, readDate in
            // TODO: Use correct formatter
            let formattedDate = Message.shortDateTimeFormatter.string(from: readDate)
            return MessageDetailsCellDescription(user: user, subtitle: formattedDate)
        }
    }

    // MARK: - Top Bar

    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - Changes

extension MessageDetailsViewController: MessageDetailsDataSourceObserver {

    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadData()
    }

    func detailsHeaderDidChange(_ dataSource: MessageDetailsDataSource) {
        configureTopBar()
    }

    func messageDidBecomeUnavailable(_ dataSource: MessageDetailsDataSource, deleted: Bool) {
        if deleted {
            dismiss(animated: true)
        }
    }

}
