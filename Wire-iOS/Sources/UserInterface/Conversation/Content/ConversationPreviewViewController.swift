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


@objc class ConversationPreviewViewController: UIViewController {

    private(set) var conversation: ZMConversation
    private var contentViewController: ConversationContentViewController

    init(conversation: ZMConversation) {
        self.conversation = conversation
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
        addChildViewController(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMoveToParentViewController(self)
        view.backgroundColor = contentViewController.tableView.backgroundColor
    }

    func createConstraints() {
        constrain(view, contentViewController.view) { view, conversationView in
            conversationView.edges == inset(view.edges, 0, 16)
        }
    }

}
