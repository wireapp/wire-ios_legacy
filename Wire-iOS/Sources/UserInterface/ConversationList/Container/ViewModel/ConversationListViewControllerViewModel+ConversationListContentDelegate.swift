// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel

extension ConversationListViewController.ViewModel: ConversationListContentDelegate {
    func conversationList(_ controller: ConversationListContentController?, didSelect conversation: ZMConversation?, focusOnView focus: Bool) {
        selectedConversation = conversation
    }

    func conversationList(_ controller: ConversationListContentController?, willSelectIndexPathAfterSelectionDeleted conv: IndexPath?) {
        ZClientViewController.shared?.transitionToList(animated: true, completion: nil)
    }

    func conversationListDidScroll(_ controller: ConversationListContentController?) {
        guard let controller = controller else { return }

        viewController?.scrollViewDidScroll(scrollView: controller.collectionView)
    }

    func conversationListContentController(_ controller: ConversationListContentController?, wantsActionMenuFor conversation: ZMConversation?, fromSourceView sourceView: UIView?) {
        showActionMenu(for: conversation, from: sourceView)
    }
}

extension ConversationListViewController.ViewModel {
    func showActionMenu(for conversation: ZMConversation!, from view: UIView!) {
        guard let viewController = viewController as? UIViewController else { return }

        actionsController = ConversationActionController(conversation: conversation, target: viewController, sourceView: view)
        actionsController?.presentMenu(from: view, context: .list)
    }
}
