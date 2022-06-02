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
import CoreData

@objc public enum MessageConfirmationType: Int16 {
    case delivered, read

    static func convert(_ zmConfirmationType: Confirmation.TypeEnum) -> MessageConfirmationType {
        switch zmConfirmationType {
        case .delivered:
            return .delivered
        case .read:
            return .read
        }
    }
}

@objc(ZMMessageConfirmation) @objcMembers
open class ZMMessageConfirmation: ZMManagedObject, ReadReceipt {

    @NSManaged open var type: MessageConfirmationType
    @NSManaged open var serverTimestamp: Date?
    @NSManaged open var message: ZMMessage
    @NSManaged open var user: ZMUser

    public var userType: UserType {
        return user
    }

    override open class func entityName() -> String {
        return "MessageConfirmation"
    }

    open override var modifiedKeys: Set<AnyHashable>? {
        get {
            return Set()
        } set {
            // do nothing
        }
    }

    /// Creates a ZMMessageConfirmation objects that holds a reference to a message that was confirmed and the user who confirmed it.
    /// It can have 2 types: Delivered and Read depending on the confirmation type
    @discardableResult
    public static func createMessageConfirmations(_ confirmation: Confirmation, conversation: ZMConversation, updateEvent: ZMUpdateEvent) -> [ZMMessageConfirmation] {

        let type = MessageConfirmationType.convert(confirmation.type)

        guard
            let managedObjectContext = conversation.managedObjectContext,
            let senderUUID = updateEvent.senderUUID,
            let serverTimestamp = updateEvent.timestamp
        else {
            return []
        }

        let sender = ZMUser.fetchOrCreate(with: senderUUID, domain: updateEvent.senderDomain, in: managedObjectContext)
        let moreMessageIds = confirmation.moreMessageIds
        let confirmedMesssageIds = ([confirmation.firstMessageID] + moreMessageIds).compactMap({ UUID(uuidString: $0) })

        return confirmedMesssageIds.compactMap { confirmedMessageId in
            guard let message = ZMMessage.fetch(withNonce: confirmedMessageId, for: conversation, in: managedObjectContext),
                !message.confirmations.contains(where: { $0.user == sender && $0.type == type }) else { return nil }

            return ZMMessageConfirmation(type: type, message: message, sender: sender, serverTimestamp: serverTimestamp, managedObjectContext: managedObjectContext)
        }
    }

    convenience init(type: MessageConfirmationType, message: ZMMessage, sender: ZMUser, serverTimestamp: Date, managedObjectContext: NSManagedObjectContext) {
        let entityDescription = NSEntityDescription.entity(forEntityName: ZMMessageConfirmation.entityName(), in: managedObjectContext)!
        self.init(entity: entityDescription, insertInto: managedObjectContext)
        self.message = message
        self.user = sender
        self.type = type
        self.serverTimestamp = serverTimestamp
    }

}
