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

extension AnalyticsEvent {

    /// When the app discovers it can't decrypt a received message.
    /// - Parameter conversation: ZMConversation so we're able to get conversation attributes.
    /// - Returns: An Analytics Event
    static func failedToDecryptMessage(in conversation: ZMConversation) -> AnalyticsEvent {
        var event = AnalyticsEvent(name: "e2ee.failed_message_decryption")
        event.attributes = conversation.analyticsAttributes
        return event
    }

}
