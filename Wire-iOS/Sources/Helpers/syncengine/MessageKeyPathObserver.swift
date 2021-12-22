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

import Foundation
import WireSyncEngine

/// Observes a single key path in `MessageChangeInfo` and calls a change handler when the key path changes.
///
/// The observer is active as long as the `MessageKeyPathObserver` instance is retained.
class MessageKeyPathObserver: NSObject, ZMMessageObserver {

    typealias ChangedBlock = (_ message: ZMConversationMessage) -> Void

    private let keypath: KeyPath<MessageChangeInfo, Bool>
    private var token: Any?

    var onChanged: ChangedBlock?

    init?(message: ZMConversationMessage, keypath: KeyPath<MessageChangeInfo, Bool>, _ changed: ChangedBlock? = nil) {
        guard let session = ZMUserSession.shared() else { return nil }

        self.keypath = keypath

        super.init()

        self.onChanged = changed
        self.token = MessageChangeInfo.add(observer: self, for: message, userSession: session)
    }

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        guard changeInfo[keyPath: keypath] else { return }

        onChanged?(changeInfo.message)
    }

}
