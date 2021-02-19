//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireDataModel

extension ZMConversation {

    var analyticsAttributes: AnalyticsAttributes {
        var result = AnalyticsAttributes()

        result[.conversationType] = analyticsConversationType
        result[.conversationSize] = localParticipants.count.rounded(byFactor: 6)

        let guests = localParticipants.filter { $0.isGuest(in: self) }
        result[.conversationGuestsCount] = guests.count.rounded(byFactor: 6)
        result[.conversationProGuestsCount] = guests.filter(\.hasTeam).count.rounded(byFactor: 6)
        result[.conversationWirelessGuestsCount] = guests.filter(\.isWirelessUser).count.rounded(byFactor: 6)

        result[.conversationServices] = sortedServiceUsers.count.rounded(byFactor: 6)

        return result
    }

    private var analyticsConversationType: AnalyticsConversationType? {
        switch conversationType {
        case .oneOnOne:
            return .oneToOne
        case .group:
            return .group
        default:
            return nil
        }
    }

}

private extension AnalyticsAttributeKey {

    /// The type of conversation.
    ///
    /// Expected to refer to a value of type `AnalyticsConversationType`.

    static let conversationType = AnalyticsAttributeKey(rawValue: "conversation_type")

    /// The number of participants in the conversation.
    ///
    /// Expected to refer to a value of type `RoundedInt`.

    static let conversationSize = AnalyticsAttributeKey(rawValue: "conversation_size")

    /// The number of guests in the conversation.
    ///
    /// Expected to refer to a value of type `RoundedInt`.

    static let conversationGuestsCount = AnalyticsAttributeKey(rawValue: "conversation_guests")

    /// The number of guests in the conversation who are using Wire Pro.
    ///
    /// Expected to refer to a value of type `RoundedInt`.

    static let conversationProGuestsCount = AnalyticsAttributeKey(rawValue: "conversation_guests_pro")

    /// The number of wireless guests in the conversation.
    ///
    /// Expected to refer to a value of type `RoundedInt`.

    static let conversationWirelessGuestsCount = AnalyticsAttributeKey(rawValue: "conversation_guests_wireless")

    /// The number of services in the conversation.
    ///
    /// Expected to refer to a value of type `RoundedInt`.

    static let conversationServices = AnalyticsAttributeKey(rawValue: "conversation_services")

}

private enum AnalyticsConversationType: String, AnalyticsAttributeValue {

    case oneToOne = "one_to_one"
    case group = "group"

    var analyticsValue: String {
        return rawValue
    }

}
