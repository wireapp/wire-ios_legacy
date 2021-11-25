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

extension AnalyticsEvent {

    static func initiatedCall(asVideoCall: Bool, in conversation: ZMConversation) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "calling.initiated_call")
        event.attributes = conversation.analyticsAttributes
        event.attributes[.startedAsVideoCall] = asVideoCall
        return event
    }

}

private extension AnalyticsAttributeKey {

    /// Whether a call started as a video call.
    ///
    /// Expected to refer to a value of type `Boolean`.

    static let startedAsVideoCall = AnalyticsAttributeKey(rawValue: "call_video")
    
}
