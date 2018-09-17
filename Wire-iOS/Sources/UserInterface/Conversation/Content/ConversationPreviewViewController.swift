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
import Cartography


@objcMembers class ConversationPreviewViewController: TintColorCorrectedViewController {

    let conversation: ZMConversation
    fileprivate let actionController: ConversationActionController
    fileprivate var contentViewController: ConversationContentViewController

    init(conversation: ZMConversation, presentingViewController: UIViewController) {
        self.conversation = conversation
        self.actionController = ConversationActionController(conversation: conversation, target: presentingViewController)
        contentViewController = ConversationContentViewController(conversation: conversation)
        super.init(nibName: nil, bundle: nil)
    }

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

    func createConstraints() {
        constrain(view, contentViewController.view) { view, conversationView in
            conversationView.edges == view.edges
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: Preview Actions

    override var previewActionItems: [UIPreviewActionItem] {
        return conversation.actions.map(makePreviewAction)
    }

    private func makePreviewAction(for action: ZMConversation.Action) -> UIPreviewAction {
        return action.previewAction { [weak self] in
            guard let `self` = self else { return }
            self.actionController.handleAction(action)
        }
    }

}
