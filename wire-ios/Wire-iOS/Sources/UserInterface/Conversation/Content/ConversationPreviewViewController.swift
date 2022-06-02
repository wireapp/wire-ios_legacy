//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import UIKit
import WireSyncEngine

final class ConversationPreviewViewController: TintColorCorrectedViewController {

    let conversation: ZMConversation
    let actionController: ConversationActionController
    fileprivate var contentViewController: ConversationContentViewController

    init(conversation: ZMConversation,
         presentingViewController: UIViewController,
         sourceView: UIView?) {
        self.conversation = conversation
        actionController = ConversationActionController(conversation: conversation,
                                                        target: presentingViewController,
                                                        sourceView: sourceView)

        contentViewController = ConversationContentViewController(conversation: conversation, mediaPlaybackManager: nil, session: ZMUserSession.shared()!)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        createConstraints()
    }

    func createViews() {
        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        view.backgroundColor = contentViewController.tableView.backgroundColor
    }

    private func createConstraints() {
        guard let conversationView = contentViewController.view else { return }

        conversationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          conversationView.topAnchor.constraint(equalTo: view.topAnchor),
          conversationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          conversationView.leftAnchor.constraint(equalTo: view.leftAnchor),
          conversationView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: Preview Actions

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    override var previewActionItems: [UIPreviewActionItem] {
        return conversation.listActions.map(makePreviewAction)
    }

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    private func makePreviewAction(for action: ZMConversation.Action) -> UIPreviewAction {
        return action.previewAction { [weak self] in
            guard let `self` = self else { return }
            self.actionController.handleAction(action)
        }
    }

}
