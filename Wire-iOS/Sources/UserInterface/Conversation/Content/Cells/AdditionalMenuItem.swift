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

import Foundation

@objcMembers public final class AdditionalMenuItem: NSObject {

    public let item: UIMenuItem
    
    @objc(availableInEphemeralConversations)
    public let isAvailableInEphemeralConversations: Bool
    
    public init(item: UIMenuItem, allowedInEphemeralConversations: Bool) {
        self.item = item
        self.isAvailableInEphemeralConversations = allowedInEphemeralConversations
        super.init()
    }
    
    static func allowedInEphemeral(_ item: UIMenuItem) -> AdditionalMenuItem {
        return .init(item: item, allowedInEphemeralConversations: true)
    }
    
    static func forbiddenInEphemeral(_ item: UIMenuItem) -> AdditionalMenuItem {
        return .init(item: item, allowedInEphemeralConversations: false)
    }
}
