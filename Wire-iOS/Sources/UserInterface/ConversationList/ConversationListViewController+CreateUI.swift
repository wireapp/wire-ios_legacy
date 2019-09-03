
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

extension ConversationListViewController {
    @objc
    func setupObservers() {
        if let userSession = ZMUserSession.shared(),
            let selfUser = ZMUser.selfUser() {
            userObserverToken = UserChangeInfo.add(observer: self, for: selfUser, userSession: userSession) as Any

            initialSyncObserverToken = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }
    }

    @objc
    func createNoConversationLabel() {
        noConversationLabel = UILabel()
        noConversationLabel.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        noConversationLabel.numberOfLines = 0
        contentContainer.addSubview(noConversationLabel)
    }

    @objc
    func createBottomBarController() {
        bottomBarController = ConversationListBottomBarController(delegate: self)
        bottomBarController.showArchived = true
        addChild(bottomBarController)
        conversationListContainer.addSubview(bottomBarController.view)
        bottomBarController.didMove(toParent: self)
    }

    @objc
    func createListContentController() {
        listContentController = ConversationListContentController()
        listContentController.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: contentControllerBottomInset, right: 0)
        listContentController.contentDelegate = self

        addChild(listContentController)
        conversationListContainer.addSubview(listContentController.view)
        listContentController.didMove(toParent: self)
    }


    func createArchivedListViewController() -> ArchivedListViewController? {
        let archivedViewController = ArchivedListViewController()
        archivedViewController.delegate = self
        return archivedViewController
    }

}

extension NSAttributedString {
    static var attributedTextForNoConversationLabel: NSAttributedString? {
        guard let paragraphStyle = NSParagraphStyle.default as? NSMutableParagraphStyle else { return nil }
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.smallMediumFont,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]

        paragraphStyle.paragraphSpacing = 4

        let titleString = "conversation_list.empty.all_archived.message".localized

        let attributedString = NSAttributedString(string: titleString.uppercased(), attributes: titleAttributes)

        return attributedString
    }
}
