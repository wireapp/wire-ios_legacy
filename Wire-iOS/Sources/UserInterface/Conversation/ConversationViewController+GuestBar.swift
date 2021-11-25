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
import WireDataModel

extension ConversationViewController {

    typealias ConversationBanner = L10n.Localizable.Conversation.Banner

    /// The state that the guest bar should adopt in the current configuration.
    var currentGuestBarState: GuestsBarController.State {

        let state = conversation.externalParticipantsState

        if state.isEmpty {
            return .hidden
        } else {
            return .visible(labelKey: label(for: state), identifier: identifier(for: state))
        }
    }

    func label(for state: ZMConversation.ExternalParticipantsState) -> String {
        var states: [String] = []

        if conversation.externalParticipantsState.contains(.visibleRemotes) {
            states.append(ConversationBanner.remotes)
        }

        if conversation.externalParticipantsState.contains(.visibleExternals) {
            states.append(ConversationBanner.externals)
        }

        if conversation.externalParticipantsState.contains(.visibleGuests) {
            states.append(ConversationBanner.guests)
        }

        if conversation.externalParticipantsState.contains(.visibleServices) {
            states.append(ConversationBanner.services)
        }

        let head = states[0]
        let tail = states.dropFirst().map({ $0.localizedLowercase })
        let list = ([head] + tail).joined(separator: ConversationBanner.separator)

        if state == .visibleServices {
            return ConversationBanner.areActive(list)
        } else {
            return ConversationBanner.arePresent(list)
        }
    }

    func identifier(for state: ZMConversation.ExternalParticipantsState) -> String {
        var identifiers: [String] = []

        if conversation.externalParticipantsState.contains(.visibleRemotes) {
            identifiers.append("remotes")
        }

        if conversation.externalParticipantsState.contains(.visibleExternals) {
            identifiers.append("externals")
        }

        if conversation.externalParticipantsState.contains(.visibleGuests) {
            identifiers.append("guests")
        }

        if conversation.externalParticipantsState.contains(.visibleServices) {
            identifiers.append("services")
        }

        return "has\(identifiers.joined(separator: "and"))"
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
