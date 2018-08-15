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

@objc enum GuestBarState: Int {
    case hidden
    case guestsPresent
    case servicesPresent
    case guestsAndServicesPresent
}

extension GuestBarState {
    var displayString: String {
        return localizationKey.localized.uppercased()
    }
    
    private var localizationKey: String {
        switch self {
        case .hidden: return ""
        case .guestsPresent: return "conversation.guests_present"
        case .servicesPresent: return "conversation.services_present"
        case .guestsAndServicesPresent: return "conversation.guests_services_present"
        }
    }
    
    var accessibilityIdentifier: String? {
        switch self {
        case .hidden: return nil
        case .guestsPresent: return "label.conversationview.hasguests"
        case .servicesPresent: return "label.conversationview.hasservices"
        case .guestsAndServicesPresent: return "label.conversationview.hasguestsandservices"
        }
    }
}
