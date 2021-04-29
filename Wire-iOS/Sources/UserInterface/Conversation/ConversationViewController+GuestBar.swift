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

import UIKit
import FormatterKit

extension ConversationViewController {

    /// The state that the guest bar should adopt in the current configuration.
    var currentGuestBarState: GuestsBarController.State {
        typealias Conversation = L10n.Localizable.Conversation

        switch conversation.externalParticipantsState {
        case [.visibleGuests]:
            return .visible(labelKey: Conversation.guestsPresent, identifier: "label.conversationview.hasguests")
        case [.visibleServices]:
            return .visible(labelKey: Conversation.servicesPresent, identifier: "label.conversationview.hasservices")
        case [.visibleExternals]:
            return .visible(labelKey: Conversation.externalsPresent, identifier: "label.conversationview.hasexternals")
        case [.visibleGuests, .visibleServices]:
            return .visible(labelKey: Conversation.guestsServicesPresent, identifier: "label.conversationview.hasguestsandservices")
        case [.visibleExternals, .visibleServices]:
            return .visible(labelKey: Conversation.externalsServicesPresent, identifier: "label.conversationview.hasexternalsandservices")
        case [.visibleExternals, .visibleGuests]:
            return .visible(labelKey: Conversation.externalsGuestsPresent, identifier: "label.conversationview.hasexternalsandguests")
        case [.visibleExternals, .visibleGuests, .visibleServices]:
            return .visible(labelKey: Conversation.externalsGuestsServicesPresent, identifier: "label.conversationview.hasexternalsandguestsandservices")
        default:
            return .hidden
        }
    }

    /// Updates the visibility of the guest bar.
    func updateGuestsBarVisibility() {
        let currentState = self.currentGuestBarState
        guestsBarController.state = currentState

        if case .hidden = currentState {
            conversationBarController.dismiss(bar: guestsBarController)
        } else {
            conversationBarController.present(bar: guestsBarController)
        }
    }

    func setGuestBarForceHidden(_ isGuestBarForceHidden: Bool) {
        if isGuestBarForceHidden {
            guestsBarController.setState(.hidden, animated: true)
            guestsBarController.shouldIgnoreUpdates = true
        } else {
            guestsBarController.shouldIgnoreUpdates = false
            updateGuestsBarVisibility()
        }
    }

}
