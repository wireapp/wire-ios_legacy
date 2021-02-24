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
    func setState(_ state: ConversationListState,
                  animated: Bool,
                  completion: Completion? = nil) {
        if self.state == state {
            completion?()
            return
        }
        self.state = state

        switch state {
        case .conversationList:
            view.alpha = 1

            if let presentedViewController = presentedViewController {
                presentedViewController.dismiss(animated: true, completion: completion)
            } else {
                completion?()
            }
        case .peoplePicker:
            let startUIViewController = createPeoplePickerController()
            let navigationWrapper = startUIViewController.wrapInNavigationController(navigationControllerClass: ClearBackgroundNavigationController.self)

            show(navigationWrapper, animated: true) {
                startUIViewController.showKeyboardIfNeeded()
                completion?()
            }
        case .archived:
            show(createArchivedListViewController(), animated: animated, completion: completion)
        }
    }

    func selectInboxAndFocusOnView(focus: Bool) {
        setState(.conversationList, animated: false)
        listContentController.selectInboxAndFocus(onView: focus)
    }

}
