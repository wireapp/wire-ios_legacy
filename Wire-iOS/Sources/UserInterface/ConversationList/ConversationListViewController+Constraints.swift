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

        var constraints :[NSLayoutConstraint] = conversationListContainer.fitInSuperview(exclude: [.top], activate: false).values.map{$0}

//        conversationListContainer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: ALEdgeTop)
        let bottomBarControllerConstraints = bottomBarController.view.fitInSuperview(exclude: [.top], activate: false)

        bottomBarBottomOffset = bottomBarControllerConstraints[.bottom]

        constraints += bottomBarControllerConstraints.values.map{$0}
//        bottomBarController.view.autoPinEdge(toSuperviewEdge: ALEdgeLeft)
//        bottomBarController.view.autoPinEdge(toSuperviewEdge: ALEdgeRight)
//        bottomBarBottomOffset = bottomBarController.view.autoPinEdge(toSuperviewEdge: ALEdgeBottom)

        networkStatusViewController.createConstraintsInParentController(bottomView: topBar, controller: self)

        constraints += topBar.fitInSuperview(exclude: [.top, .bottom], activate: false).values.map{$0}

//        topBar.autoPinEdge(toSuperviewEdge: ALEdgeLeft)
//        topBar.autoPinEdge(toSuperviewEdge: ALEdgeRight)

        constraints += [topBar.bottomAnchor.constraint(equalTo: conversationListContainer.topAnchor),
//        topBar.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: conversationListContainer)

        contentContainer.bottomAnchor.constraint(equalTo: safeBottomAnchor),
        contentContainer.topAnchor.constraint(equalTo: safeTopAnchor),
        contentContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
        contentContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)]

        constraints += noConversationLabel.centerInSuperview(activate: false)
        constraints += noConversationLabel.setDimensions(width: 240, height: 120, activate: false).array

//        noConversationLabel.autoCenterInSuperview()
//        noConversationLabel.autoSetDimension(ALDimensionHeight, toSize: 120.0)
//        noConversationLabel.autoSetDimension(ALDimensionWidth, toSize: 240.0)

        onboardingHint.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: bottomBarController.view)
        onboardingHint.autoPinEdge(toSuperviewMargin: ALEdgeLeft)
        onboardingHint.autoPinEdge(toSuperviewMargin: ALEdgeRight)

        listContentController.view.autoPinEdge(toSuperviewEdge: ALEdgeTop)
        listContentController.view.autoPinEdge(ALEdgeBottom, toEdge: ALEdgeTop, ofView: bottomBarController.view)
        listContentController.view.autoPinEdge(toSuperviewEdge: ALEdgeLeading)
        listContentController.view.autoPinEdge(toSuperviewEdge: ALEdgeTrailing)

        NSLayoutConstraint.activate(constraints)
    }
}

/*
 - (void)createViewConstraints
 {
 [self.conversationListContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];

 [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeLeft];
 [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeRight];
 self.bottomBarBottomOffset = [self.bottomBarController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];

 [self.networkStatusViewController createConstraintsInParentControllerWithBottomView:self.topBar controller:self];

 [self.topBar autoPinEdgeToSuperviewEdge:ALEdgeLeft];
 [self.topBar autoPinEdgeToSuperviewEdge:ALEdgeRight];

 [self.topBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.conversationListContainer];

 [[self.contentContainer.bottomAnchor constraintEqualToAnchor:self.safeBottomAnchor] setActive:YES];
 [[self.contentContainer.topAnchor constraintEqualToAnchor:self.safeTopAnchor] setActive:YES];
 [[self.contentContainer.leadingAnchor constraintEqualToAnchor:self.view.safeLeadingAnchor] setActive:YES];
 [[self.contentContainer.trailingAnchor constraintEqualToAnchor:self.view.safeTrailingAnchor] setActive:YES];

 [self.noConversationLabel autoCenterInSuperview];
 [self.noConversationLabel autoSetDimension:ALDimensionHeight toSize:120.0f];
 [self.noConversationLabel autoSetDimension:ALDimensionWidth toSize:240.0f];

 [self.onboardingHint autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomBarController.view];
 [self.onboardingHint autoPinEdgeToSuperviewMargin:ALEdgeLeft];
 [self.onboardingHint autoPinEdgeToSuperviewMargin:ALEdgeRight];

 [self.listContentController.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
 [self.listContentController.view autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomBarController.view];
 [self.listContentController.view autoPinEdgeToSuperviewEdge:ALEdgeLeading];
 [self.listContentController.view autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
 }
 */
