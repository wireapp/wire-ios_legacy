//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import UIKit

protocol ProfileFooterViewDelegate: AnyObject {

    /// Called when the footer wants to perform a single action, from the left button.
    func footerView(_ footerView: ProfileFooterView, shouldPerformAction action: ProfileAction)

    /// Called when the footer wants to present the list of actions, from the right button.
    func footerView(_ footerView: ProfileFooterView, shouldPresentMenuWithActions actions: [ProfileAction])

}

/**
 * The footer of to use in the profile details screen.
 */

final class ProfileFooterView: ConversationDetailFooterView {

    /// The object that will perform the actions on demand.
    weak var delegate: ProfileFooterViewDelegate?

    /// The action on the left button.
    var leftAction: ProfileAction?

    /// The actions hidden behind the ellipsis on the right.
    var rightActions: [ProfileAction]?

    // MARK: - Configuration

    override func setupButtons() {
        leftButton.accessibilityIdentifier = "left_button"
        rightButton.accessibilityIdentifier = "right_button"
        rightButton.accessibilityLabel = "meta.menu.accessibility_more_options_button".localized
    }

    /**
     * Configures the footer to display the specified actions.
     * - parameter actions: The actions to display in the footer.
     */

    func configure(with actions: [ProfileAction]) {
        // Separate the last and first actions
        var leftAction = actions.first
        var rightActions: [ProfileAction]

        if leftAction?.isEligibleForKeyAction == true {
            rightActions = Array(actions.dropFirst())
        } else {
            // If the first action is not eligible for key action, display
            // everything on the right
            leftAction = nil
            rightActions = actions
        }

        self.leftAction = leftAction
        self.rightActions = rightActions

        // Display the left action
        if let leftAction = leftAction {
            leftButton.setTitle(leftAction.buttonText.localizedUppercase, for: .normal)
            leftIcon = leftAction.keyActionIcon
        }

        // Display or hide the right action ellipsis
        if rightActions.isEmpty {
            rightIcon = nil
            rightButton.isHidden = true
        } else {
            rightIcon = .ellipsis
            rightButton.isHidden = false
        }
    }

    // MARK: - Events

    override func leftButtonTapped(_ sender: IconButton) {
        guard let leftAction = self.leftAction else { return }
        delegate?.footerView(self, shouldPerformAction: leftAction)
    }

    override func rightButtonTapped(_ sender: IconButton) {
        guard let rightActions = self.rightActions else { return }
        delegate?.footerView(self, shouldPresentMenuWithActions: rightActions)
    }

}
