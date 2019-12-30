
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

final class MockSystemMessage: NSObject,
                               ZMConversationMessage,
                               ZMSystemMessageData,
                               SystemMessageNewConversationProperties {
    //MARK: - SystemMessageNewConversationProperties
    var numberOfGuestsAdded: Int16 = 0
    
    var allTeamUsersAdded: Bool = true
    
    //MARK: - ZMConversationMessage
    var nonce: UUID?
    
    var sender: UserType?
    
    var serverTimestamp: Date?
    
    var conversation: ZMConversation?
    
    var deliveryState: ZMDeliveryState = .delivered
    
    var isSent: Bool = true
    
    var readReceipts: [ReadReceipt] = []
    
    var needsReadConfirmation: Bool = false
    
    var textMessageData: ZMTextMessageData?
    
    var imageMessageData: ZMImageMessageData?
    
    /// isSystem == true when this is non nil
    var systemMessageData: ZMSystemMessageData?
    
    var knockMessageData: ZMKnockMessageData?
    
    var fileMessageData: ZMFileMessageData?
    
    var locationMessageData: LocationMessageData?
    
    var usersReaction: Dictionary<String, [ZMUser]> = [:]
    
    func resend() {
        
    }
    
    var canBeDeleted: Bool = true
    
    var hasBeenDeleted: Bool = false
    
    var updatedAt: Date?
    
    func startSelfDestructionIfNeeded() -> Bool {
        return false
    }
    
    var isEphemeral: Bool = false
    
    var deletionTimeout: TimeInterval = 0
    
    var isObfuscated: Bool = false
    
    var destructionDate: Date?
    
    var causedSecurityLevelDegradation: Bool = false
    
    func markAsUnread() {
        
    }
    
    var canBeMarkedUnread: Bool = true
    
    var replies: Set<ZMMessage> = Set()
    
    var objectIdentifier: String = ""
    
    var linkAttachments: [LinkAttachment]?
    
    var needsLinkAttachmentsUpdate: Bool = false
    
    var systemMessageType: ZMSystemMessageType = .invalid
    
    //MARK: - ZMSystemMessageData
    var users: Set<ZMUser> = Set()
    
    var clients: Set<AnyHashable> = Set()
    
    var addedUsers: Set<ZMUser> = Set()
    
    var removedUsers: Set<ZMUser> = Set()
    
    var text: String?
    
    var needsUpdatingUsers: Bool = true
    
    var duration: TimeInterval = 0
    
    /**
     Only filled for .performedCall & .missedCall
     */
    var childMessages: Set<AnyHashable> = Set()
    
    var parentMessage: ZMSystemMessageData?
    
    var userIsTheSender: Bool = true
    
    var messageTimer: NSNumber?
}

