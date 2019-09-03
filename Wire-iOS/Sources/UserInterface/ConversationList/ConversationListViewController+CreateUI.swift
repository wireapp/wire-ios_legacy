
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
        conversationListContainer?.addSubview(bottomBarController.view)
        bottomBarController.didMove(toParent: self)
    }

    @objc
    func createListContentController() {
        listContentController = ConversationListContentController()
        listContentController.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: contentControllerBottomInset, right: 0)
        listContentController.contentDelegate = self

        addChild(listContentController)
        conversationListContainer?.addSubview(listContentController.view)
        listContentController.didMove(toParent: self)
    }

    func createArchivedListViewController() -> ArchivedListViewController {
        let archivedViewController = ArchivedListViewController()
        archivedViewController.delegate = self
        return archivedViewController
    }

    ///TODO: mv
    func setBackgroundColorPreference(_ color: UIColor?) {
        UIView.animate(withDuration: 0.4, animations: {
            self.view.backgroundColor = color
            self.listContentController.view.backgroundColor = color
        })
    }

    func showNoContactLabel() {
        if state == .conversationList {
            UIView.animate(withDuration: 0.20, animations: {
                self.noConversationLabel.alpha = self.hasArchivedConversations ? 1.0 : 0.0
                self.onboardingHint?.alpha = self.hasArchivedConversations ? 0.0 : 1.0
            })
        }
    }

    @objc(hideNoContactLabelAnimated:)
    func hideNoContactLabel(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.20 : 0.0, animations: {
            self.noConversationLabel.alpha = 0.0
            self.onboardingHint?.alpha = 0.0
        })
    }

    @objc
    func updateNoConversationVisibility() {
        if !hasConversations {
            showNoContactLabel()
        } else {
            hideNoContactLabel(animated: true)
        }
    }

    var hasConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }

        let conversationsCount = ZMConversationList.conversations(inUserSession: session).count + ZMConversationList.pendingConnectionConversations(inUserSession: session).count
        return conversationsCount > 0
    }

    var hasArchivedConversations: Bool {
        guard let session = ZMUserSession.shared() else { return false }

        return ZMConversationList.archivedConversations(inUserSession: session).count > 0
    }

    func updateBottomBarSeparatorVisibility(with controller: ConversationListContentController?) {
        let controllerHeight = controller?.view.bounds.height
        let contentHeight = controller?.collectionView.contentSize.height
        let offsetY = controller?.collectionView.contentOffset.y
        let showSeparator = (contentHeight ?? 0.0) - (offsetY ?? 0.0) + contentControllerBottomInset > controllerHeight

        if bottomBarController.showSeparator != showSeparator {
            bottomBarController.showSeparator = showSeparator
        }
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
