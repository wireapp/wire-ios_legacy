//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


typealias UserNameLength = Int


protocol Event {
    var name: String { get }
    var attributes: [AnyHashable: Any]? { get }
}

extension Event {
    var attributes: [AnyHashable: Any]? {
        return nil
    }
}

enum UserNameEvent {

    enum Settings: Event {
        case enteredUsername(withLength: UserNameLength)
        case setUsername(withLength: UserNameLength)

        var name: String {
            switch self {
            case .enteredUsername(_): return "settings.entered_username" // when user enters an attempt to set username
            case .setUsername(_): return "settings.set_username" // when username was successfully set
            }
        }

        var attributes: [AnyHashable : Any]? {
            switch self {
            case .enteredUsername(let length): return ["length": length]
            case .setUsername(let length): return ["length": length]
            }
        }
    }

    enum Takeover: Event {
        case shown, openedSettings, openedFAQ, keepSuggested

        var name: String {
            switch self {
            case .shown: return "onboarding.seen_username_screen"
            case .keepSuggested: return "onboarding.kept_generated_username"
            case .openedSettings: return "onboarding.opened_username_settings" // when user taps button to choose his own username
            case .openedFAQ: return "onboarding.opened_username_faq"
            }
        }
    }

}


extension Analytics {

    func tag(_ event: Event) {
        tagEvent(event.name, attributes: event.attributes)
    }
    
}
