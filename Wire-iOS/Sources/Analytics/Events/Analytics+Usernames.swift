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


@objc public enum SearchContext: UInt {
    case startUI, addContacts

    var value: String {
        switch self {
        case .startUI: return "startui"
        case .addContacts: return "add_to_conversation"
        }
    }
}


enum UserNameEvent {

    enum Settings: Event {
        case enteredUsernameScreen
        case setUsername(withLength: UserNameLength)

        var name: String {
            switch self {
            case .enteredUsernameScreen: return "settings.edited_username" // when user enters the screen to set a new username
            case .setUsername(_): return "settings.set_username" // when username was successfully set
            }
        }

        var attributes: [AnyHashable : Any]? {
            switch self {
            case .enteredUsernameScreen: return nil
            case .setUsername(let length): return ["length": length]
            }
        }
    }

    enum Takeover: Event {
        case shown, openedSettings, openedFAQ, keepSuggested(success: Bool)

        var name: String {
            switch self {
            case .shown: return "onboarding.seen_username_screen"
            case .keepSuggested(_): return "onboarding.kept_generated_username"
            case .openedSettings: return "onboarding.opened_username_settings" // when user taps button to choose his own username
            case .openedFAQ: return "onboarding.opened_username_faq"
            }
        }

        var attributes: [AnyHashable : Any]? {
            switch self {
            case .keepSuggested(success: let success): return ["outcome" : success ? "success" : "fail"]
            default: return nil
            }
        }
    }

    enum Search: Event {

        case entered(unsernameOnly: Bool, context: SearchContext)
        case openedExistingConversation(type: ZMConversationType)
        case selectedUnconnectedUser(state: AnalyticsConnectionState, context: SearchContext)

        var name: String {
            switch self {
            case .entered(unsernameOnly: _): return "connect.entered_search"
            case .openedExistingConversation(_): return "connect.opened_conversation"
            case .selectedUnconnectedUser(_): return "connect.selected_user_from_search"
            }
        }

        var attributes: [AnyHashable : Any]? {
            switch self {
            case .entered(unsernameOnly: let username, context: let context):
                return ["by_username_only": username ? "true" : "false", "context": context.value]
            case .openedExistingConversation(type: let type):
                return ["conversation_type": type == .oneOnOne ? "one_to_one" : "group"]
            case .selectedUnconnectedUser(state: let type, context: let context):
                return ["connection_type": type.value, "context": context.value]
            }
        }
    }

}


@objc public enum AnalyticsConnectionState: UInt {
    case outgoing, incoming, blocked, connected, unconnected

    var value: String {
        switch self {
        case .outgoing: return "pending_outgoing"
        case .incoming: return "pending_incoming"
        case .blocked: return "blocked"
        case .connected: return "connected"
        case .unconnected: return "unconnected"
        }
    }

}


extension Analytics {

    func tag(_ event: Event) {
        tagEvent(event.name, attributes: event.attributes)
    }
    
}


@objc public protocol AnalyticsConnectionStateProvider: NSObjectProtocol {
    var analyticsConnectionState: AnalyticsConnectionState { get }
}


extension ZMUser: AnalyticsConnectionStateProvider {

    public var analyticsConnectionState: AnalyticsConnectionState {
        if isBlocked {
            return .blocked
        }
        if isPendingApprovalBySelfUser {
            return .incoming
        }
        if isPendingApprovalByOtherUser {
            return .outgoing
        }
        return isConnected ? .connected : .unconnected
    }

}


extension ZMSearchUser: AnalyticsConnectionStateProvider {

    public var analyticsConnectionState: AnalyticsConnectionState {
        return user?.analyticsConnectionState ?? .unconnected
    }
    
}


// MARK: – Objective-C Interoperability


extension Analytics {

    @objc(tagEnteredSearchWithLeadingAtSign:context:)
    public func tagEnteredSearch(leadingAt usernameOnly: Bool, context: SearchContext) {
        tag(UserNameEvent.Search.entered(unsernameOnly: usernameOnly, context: context))
    }

    @objc(tagOpenedExistingConversationWithType:)
    public func tagOpenedExistingConversation(with type: ZMConversationType) {
        guard type == .oneOnOne || type == .group else { return }
        tag(UserNameEvent.Search.openedExistingConversation(type: type))
    }

    @objc(tagSelectedSearchResultWithConnectionStateProvider:context:)
    public func tagSelectedUnconnectedUser(with provider: AnalyticsConnectionStateProvider, context: SearchContext) {
        tag(UserNameEvent.Search.selectedUnconnectedUser(state: provider.analyticsConnectionState, context: context))
    }

}
