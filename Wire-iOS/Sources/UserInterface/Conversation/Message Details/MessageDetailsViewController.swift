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
 * A view controller wrapping the message details.
 */

final class MessageDetailsViewController: UIViewController, ModalTopBarDelegate {

    /**
     * The collection of view controllers displaying the content.
     */

    enum ViewControllers {
        /// We are displaying the combined view.
        case combinedView(readReceipts: MessageDetailsContentViewController, reactions: MessageDetailsContentViewController)

        /// We are displaying the single view.
        case singleView(MessageDetailsContentViewController)

        /// The read receipts view controller.
        var readReceipts: MessageDetailsContentViewController {
            switch self {
            case .combinedView(let readReceipts, _): return readReceipts
            case .singleView(let viewController): return viewController
            }
        }

        /// The reactions view controller.
        var reactions: MessageDetailsContentViewController {
            switch self {
            case .combinedView(_, let reactions): return reactions
            case .singleView(let viewController): return viewController
            }
        }

        /// All the view controllers.
        var all: [MessageDetailsContentViewController] {
            switch self {
            case .combinedView(let readReceipts, let reactions):
                return [readReceipts, reactions]
            case .singleView(let viewController):
                return [viewController]
            }
        }
    }

    // MARK: - Properties

    /// The displayed message.
    let message: ZMConversationMessage

    /// The data source for the message details.
    let dataSource: MessageDetailsDataSource

    // MARK: - UI Elements

    let container: TabBarController
    let topBar = ModalTopBar()
    let viewControllers: ViewControllers

    // MARK: - Initialization

    /**
     * Creates a details view controller for the specified message displaying the first available tab by default.
     * - parameter message: The message to display the details of.
     */

    convenience init(message: ZMConversationMessage) {
        self.init(message: message, preferredDisplayMode: .receipts)
    }

    /**
     * Creates a details view controller for the specified message.
     * - parameter message: The message to display the details of.
     * - parameter preferredDisplayMode: The display mode to display by default when there are multiple
     * tabs. Note that this object is only an indication, and will not override the displayed content
     * if the data source says it is unavailable for the message.
     */

    init(message: ZMConversationMessage, preferredDisplayMode: MessageDetailsDisplayMode) {
        self.message = message
        self.dataSource = MessageDetailsDataSource(message: message)

        // Setup the appropriate view controllers
        switch dataSource.displayMode {
        case .combined:
            let readReceiptsViewController = MessageDetailsContentViewController(contentType: .receipts(enabled: dataSource.supportsReadReceipts), conversation: dataSource.conversation)
            let reactionsViewController = MessageDetailsContentViewController(contentType: .reactions, conversation: dataSource.conversation)
            viewControllers = .combinedView(readReceipts: readReceiptsViewController, reactions: reactionsViewController)

        case .reactions:
            let reactionsViewController = MessageDetailsContentViewController(contentType: .reactions, conversation: dataSource.conversation)
            viewControllers = .singleView(reactionsViewController)

        case .receipts:
            let readReceiptsViewController = MessageDetailsContentViewController(contentType: .receipts(enabled: dataSource.supportsReadReceipts), conversation: dataSource.conversation)
            viewControllers = .singleView(readReceiptsViewController)
        }

        container = TabBarController(viewControllers: viewControllers.all)

        if case .combined = dataSource.displayMode {
            let tabIndex = preferredDisplayMode == .reactions ? 1 : 0
            container.selectIndex(tabIndex, animated: false)
        }

        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .formSheet
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
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
        topBar.backgroundColor = UIColor.from(scheme: .barBackground)
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
            container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data

    func reloadData() {
        switch dataSource.displayMode {
        case .combined:
            viewControllers.reactions.updateData(dataSource.reactions)
            viewControllers.readReceipts.updateData(dataSource.readReceipts)

        case .reactions:
            viewControllers.reactions.updateData(dataSource.reactions)

        case .receipts:
            viewControllers.readReceipts.updateData(dataSource.readReceipts)
        }
    }

    private func reloadFooters() {
        viewControllers.all.forEach {
            $0.subtitle = dataSource.subtitle
            $0.accessibleSubtitle = dataSource.accessibilitySubtitle
        }
    }

    // MARK: - Top Bar

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }

    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        dismiss(animated: true)
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
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

}
