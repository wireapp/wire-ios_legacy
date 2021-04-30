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
        typealias ConversationBanner = L10n.Localizable.Conversation.Banner

        switch conversation.externalParticipantsState {
        case [.visibleGuests]:
            return .visible(labelKey: ConversationBanner.guestsPresent, identifier: "label.conversationview.hasguests")
        case [.visibleServices]:
            return .visible(labelKey: ConversationBanner.servicesPresent, identifier: "label.conversationview.hasservices")
        case [.visibleExternals]:
            return .visible(labelKey: ConversationBanner.externalsPresent, identifier: "label.conversationview.hasexternals")
        case [.visibleGuests, .visibleServices]:
            return .visible(labelKey: ConversationBanner.guestsServicesPresent, identifier: "label.conversationview.hasguestsandservices")
        case [.visibleExternals, .visibleServices]:
            return .visible(labelKey: ConversationBanner.externalsServicesPresent, identifier: "label.conversationview.hasexternalsandservices")
        case [.visibleExternals, .visibleGuests]:
            return .visible(labelKey: ConversationBanner.externalsGuestsPresent, identifier: "label.conversationview.hasexternalsandguests")
        case [.visibleExternals, .visibleGuests, .visibleServices]:
            return .visible(labelKey: ConversationBanner.externalsGuestsServicesPresent, identifier: "label.conversationview.hasexternalsandguestsandservices")
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
