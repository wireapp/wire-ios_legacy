
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

protocol InputBarConversationType {
    var typingUsers: [UserType] { get }
    var hasDraftMessage: Bool { get }
    var connectedUserType: UserType? { get } ///TODO: merge with ConnectionRequest protocol
    var draftMessage: DraftMessage? { get }
    
    var messageDestructionTimeoutValue: TimeInterval { get }
    var messageDestructionTimeout: MessageDestructionTimeout? { get }
    
    var conversationType: ZMConversationType { get }
    var hasSyncedMessageDestructionTimeout: Bool { get }
    
    var timeoutImage: UIImage? { get }
    var disabledTimeoutImage: UIImage? { get }
    
    func setIsTyping(_ isTyping: Bool)
    
    var isReadOnly: Bool { get }
    var displayName: String { get }
}

extension ZMConversation: InputBarConversationType {}
