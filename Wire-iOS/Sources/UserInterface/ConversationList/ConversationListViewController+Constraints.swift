//
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
    func createViewConstraints() {
        guard let conversationListContainer = conversationListContainer,
              let onboardingHint = onboardingHint,
              let bottomBar = bottomBarController.view,
              let listContent = listContentController.view else { return }




        [conversationListContainer,
         bottomBar,
         networkStatusViewController.view,
         topBarViewController.view,
         contentContainer,
         noConversationLabel,
         onboardingHint,
         listContent].forEach() { $0?.translatesAutoresizingMaskIntoConstraints = false }

        bottomBarBottomOffset = bottomBar.bottomAnchor.constraint(equalTo: bottomBar.superview!.bottomAnchor)

        let constraints: [NSLayoutConstraint] = [
            conversationListContainer.bottomAnchor.constraint(equalTo: conversationListContainer.superview!.bottomAnchor),
            conversationListContainer.leadingAnchor.constraint(equalTo: conversationListContainer.superview!.leadingAnchor),
            conversationListContainer.trailingAnchor.constraint(equalTo: conversationListContainer.superview!.trailingAnchor),

            bottomBar.leftAnchor.constraint(equalTo: bottomBar.superview!.leftAnchor),
            bottomBar.rightAnchor.constraint(equalTo: bottomBar.superview!.rightAnchor),
            bottomBarBottomOffset,

            topBarViewController.view.leftAnchor.constraint(equalTo: topBarViewController.view.superview!.leftAnchor),
            topBarViewController.view.rightAnchor.constraint(equalTo: topBarViewController.view.superview!.rightAnchor),
            topBarViewController.view.bottomAnchor.constraint(equalTo: conversationListContainer.topAnchor),

            contentContainer.bottomAnchor.constraint(equalTo: safeBottomAnchor),
            contentContainer.topAnchor.constraint(equalTo: safeTopAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),

            noConversationLabel.centerXAnchor.constraint(equalTo: noConversationLabel.superview!.centerXAnchor),
            noConversationLabel.centerYAnchor.constraint(equalTo: noConversationLabel.superview!.centerYAnchor),
            noConversationLabel.heightAnchor.constraint(equalToConstant: 120),
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240),

            onboardingHint.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            onboardingHint.leftAnchor.constraint(equalTo: onboardingHint.superview!.leftAnchor),
            onboardingHint.rightAnchor.constraint(equalTo: onboardingHint.superview!.rightAnchor),

            listContent.topAnchor.constraint(equalTo: listContent.superview!.topAnchor),
            listContent.leadingAnchor.constraint(equalTo: listContent.superview!.leadingAnchor),
            listContent.trailingAnchor.constraint(equalTo: listContent.superview!.trailingAnchor),
            listContent.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ]

        ///TODO: merge this method and activate the constraints in a batch
        networkStatusViewController.createConstraintsInParentController(bottomView: topBarViewController.view, controller: self)

        NSLayoutConstraint.activate(constraints)
    }
}
