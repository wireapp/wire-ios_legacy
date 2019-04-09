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

        [contentContainer,
         conversationListContainer,
         noConversationLabel,
         bottomBarController.view,
         topBar,
         networkStatusViewController.view,
         onboardingHint,
         listContentController.view].forEach() { $0.translatesAutoresizingMaskIntoConstraints = false }

        var constraints :[NSLayoutConstraint] = conversationListContainer.fitInSuperview(exclude: [.top], activate: false).map{$0.value}

        let bottomBarControllerConstraints = bottomBarController.view.fitInSuperview(exclude: [.top], activate: false)

        bottomBarBottomOffset = bottomBarControllerConstraints[.bottom]

        constraints += bottomBarControllerConstraints.values

        networkStatusViewController.createConstraintsInParentController(bottomView: topBar, controller: self)

        constraints += topBar.fitInSuperview(exclude: [.top, .bottom], activate: false).values

        constraints += [topBar.bottomAnchor.constraint(equalTo: conversationListContainer.topAnchor),

        contentContainer.bottomAnchor.constraint(equalTo: safeBottomAnchor),
        contentContainer.topAnchor.constraint(equalTo: safeTopAnchor),
        contentContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
        contentContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)]

        constraints += noConversationLabel.centerInSuperview(activate: false)
        constraints += noConversationLabel.setDimensions(width: 240, height: 120, activate: false).array

        constraints += [onboardingHint.bottomAnchor.constraint(equalTo: bottomBarController.view.topAnchor)]

        constraints += onboardingHint.fitInSuperview(exclude: [.top, .bottom], activate: false).values

        constraints += listContentController.view.fitInSuperview(exclude: [.bottom], activate: false).values
        constraints += [listContentController.view.bottomAnchor.constraint(equalTo: bottomBarController.view.topAnchor)]

        NSLayoutConstraint.activate(constraints)
    }
}
