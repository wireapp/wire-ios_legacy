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

class MessageDetailsViewController: TabBarController {

    let message: ZMConversationMessage
    let dataSource: MessageDetailsDataSource

    let topBar = ModalTopBar()
    var tabBar: TabBar?

    var reactionsViewController = MesageDetailsContentViewController(contentType: .reactions)
    var readReceiptsViewController = MesageDetailsContentViewController(contentType: .receipts)

    // MARK: - Initialization

    init(message: ZMConversationMessage) {
        self.message = message
        self.dataSource = MessageDetailsDataSource(message: message)

        var viewControllers: [UIViewController]

        switch dataSource.displayMode {
        case .combined:
            viewControllers = [reactionsViewController, readReceiptsViewController]
        case .likes:
            viewControllers = [reactionsViewController]
        case .receipts:
            viewControllers = [readReceiptsViewController]
        }

        super.init(viewControllers: viewControllers)
        isTabBarHidden = dataSource.displayMode != .combined
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the top bar
        let title: String
        let subtitle = makeSubtitle()

        switch dataSource.displayMode {
        case .combined:
            title = "message_details.combined_title".localized
        case .likes:
            title = "message_details.likes_title".localized
        case .receipts:
            title = "message_details.receipts_title".localized
        }

        view.addSubview(topBar)
        topBar.configure(title: title, subtitle: subtitle, topAnchor: safeTopAnchor)

        // Configure the tabs

        // Display initial data
        reloadData()
    }

    func makeSubtitle() -> String? {
        guard let sentDate = message.formattedReceivedDate() else {
            return nil
        }

        let sentString = "message_details.subtitle_send_date".localized(args: sentDate)
        var subtitle = sentString

        if let editedDate = message.formattedEditedDate() {
            let editedString = "message_details.subtitle_edit_date".localized(args: editedDate)
            subtitle += "\n" + editedString
        }

        return subtitle
    }
}

// MARK: - Changes

extension MessageDetailsViewController: MessageDetailsDataSourceObserver {

    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadData()
    }

    func reloadData() {
        switch dataSource.displayMode {
        case.combined:
            reactionsViewController.cells = makeReactionCells()
            readReceiptsViewController.cells = makeReceiptsCell()
        case .likes:
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

}
