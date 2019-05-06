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
            let onboardingHint = onboardingHint else { return }

        [conversationListContainer,
         bottomBarController.view,
         networkStatusViewController.view,
         topBarViewController.view,
         contentContainer,
         noConversationLabel,
         onboardingHint,
         listContentController.view].forEach() { $0.translatesAutoresizingMaskIntoConstraints = false }

        bottomBarBottomOffset = bottomBarController.view.bottomAnchor.constraint(equalTo: bottomBarController.view.superview!.bottomAnchor)

        let constraints: [NSLayoutConstraint] = [
            conversationListContainer.bottomAnchor.constraint(equalTo: conversationListContainer.superview!.bottomAnchor),
            conversationListContainer.leadingAnchor.constraint(equalTo: conversationListContainer.superview!.leadingAnchor),
            conversationListContainer.trailingAnchor.constraint(equalTo: conversationListContainer.superview!.trailingAnchor),

            bottomBarController.view.leftAnchor.constraint(equalTo: bottomBarController.view.superview!.leftAnchor),
            bottomBarController.view.rightAnchor.constraint(equalTo: bottomBarController.view.superview!.rightAnchor),
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

            onboardingHint.bottomAnchor.constraint(equalTo: bottomBarController.view.topAnchor),
            onboardingHint.leftAnchor.constraint(equalTo: onboardingHint.superview!.leftAnchor),
            onboardingHint.rightAnchor.constraint(equalTo: onboardingHint.superview!.rightAnchor),

            listContentController.view.topAnchor.constraint(equalTo: listContentController.view.superview!.topAnchor),
            listContentController.view.leadingAnchor.constraint(equalTo: listContentController.view.superview!.leadingAnchor),
            listContentController.view.trailingAnchor.constraint(equalTo: listContentController.view.superview!.trailingAnchor)
        ]

        ///TODO: merge this method and activate the constraints in a batch
        networkStatusViewController.createConstraintsInParentController(bottomView: topBarViewController.view, controller: self)

        NSLayoutConstraint.activate(constraints)
    }
}
