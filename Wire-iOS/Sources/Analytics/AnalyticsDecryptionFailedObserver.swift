// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class AnalyticsDecryptionFailedObserver: NSObject {
    private let analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(messageCannotBeDecrypted(_:)),
            name: ZMConversation.failedToDecryptMessageNotificationName,
            object: nil)
    }

    @objc
    private func messageCannotBeDecrypted(_ note: Notification?) {
        var trackingInfo: [String: Any] = [:]
        ["deviceClass",
         "cause"].forEach {
            if let value = note?.userInfo?[$0] {
                trackingInfo[$0] = value
            }
        }

        analytics.tagCannotDecryptMessage(withAttributes: trackingInfo, conversation: note?.object as? ZMConversation)
    }
}
