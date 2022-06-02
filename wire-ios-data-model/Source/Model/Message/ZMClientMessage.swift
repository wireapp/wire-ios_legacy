//
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

@objcMembers
public class ZMClientMessage: ZMOTRMessage {

    public static let linkPreviewStateKey = "linkPreviewState"
    public static let linkPreviewKey = "linkPreview"

    //// From https://github.com/wearezeta/generic-message-proto:
    //// "If payload is smaller then 256KB then OM can be sent directly"
    //// Just to be sure we set the limit lower, to 128KB (base 10)
    public static let byteSizeExternalThreshold: UInt = 128000

    /// Link Preview state
    @NSManaged public var updatedTimestamp: Date?

    /// In memory cache
    var cachedUnderlyingMessage: GenericMessage?

    public override static func entityName() -> String {
        return "ClientMessage"
    }

    open override var ignoredKeys: Set<AnyHashable>? {
        return (super.ignoredKeys ?? Set())
            .union([#keyPath(updatedTimestamp)])
    }

    public override var updatedAt: Date? {
        return updatedTimestamp
    }

    public override var hashOfContent: Data? {
        guard let serverTimestamp = serverTimestamp else {
            return nil
        }
        return underlyingMessage?.hashOfContent(with: serverTimestamp)
    }

    public override func awakeFromFetch() {
        super.awakeFromFetch()

        cachedUnderlyingMessage = nil
    }

    public override func awake(fromSnapshotEvents flags: NSSnapshotEventType) {
        super.awake(fromSnapshotEvents: flags)

        cachedUnderlyingMessage = nil
    }

    public override func didTurnIntoFault() {
        super.didTurnIntoFault()

        cachedUnderlyingMessage = nil
    }

    public override var isUpdatingExistingMessage: Bool {
        guard let content = underlyingMessage?.content else {
                return false
        }
        switch content {
        case .edited, .reaction:
            return true
        default:
            return false
        }
    }

    public static func keyPathsForValuesAffectingUnderlyingMessage() -> Set<String> {
        return Set([#keyPath(ZMClientMessage.dataSet),
                    #keyPath(ZMClientMessage.dataSet) + ".data"])
    }

    public override func expire() {
        guard
            let genericMessage = self.underlyingMessage,
            let content = genericMessage.content else {
                super.expire()
                return
        }

        switch content {
        case .edited:
            // Replace the nonce with the original
            // This way if we get a delete from a different device while we are waiting for the response it will delete this message
            let originalID = underlyingMessage.flatMap { UUID(uuidString: $0.edited.replacingMessageID) }
            nonce = originalID
        case .buttonAction:
            guard
                let managedObjectContext = managedObjectContext,
                let conversation = conversation else {
                    return
            }
            ZMClientMessage.expireButtonState(forButtonAction: genericMessage.buttonAction,
                                              forConversation: conversation,
                                              inContext: managedObjectContext)
        default:
            break
        }
        super.expire()
    }

    public override func resend() {
        if let genericMessage = underlyingMessage,
            case .edited? = genericMessage.content {
            // Re-apply the edit since we've restored the orignal nonce when the message expired
            editText(self.textMessageData?.messageText ?? "",
                     mentions: self.textMessageData?.mentions ?? [],
                     fetchLinkPreview: true)
        }
        super.resend()
    }

    public override func update(withPostPayload payload: [AnyHashable: Any], updatedKeys: Set<AnyHashable>?) {
        // we don't want to update the conversation if the message is a confirmation message
        guard
            let genericMessage = underlyingMessage,
            let content = genericMessage.content else {
                return
        }
        switch content {
        case .confirmation, .reaction:
            return
        case .deleted:
            let originalID = UUID(uuidString: genericMessage.deleted.messageID)
            guard
                let managedObjectContext = managedObjectContext,
                let conversation = conversation else {
                    return
            }

            let original = ZMMessage.fetch(withNonce: originalID, for: conversation, in: managedObjectContext)
            original?.sender = nil
            original?.senderClientID = nil
        case .edited:
            if let nonce = self.nonce(fromPostPayload: payload),
                self.nonce != nonce {
                Logging.messageProcessing.error("sent message response nonce does not match")
                return
            }

            if let serverTimestamp = (payload as NSDictionary).optionalDate(forKey: "time") {
                updatedTimestamp = serverTimestamp
            }
        default:
            super.update(withPostPayload: payload, updatedKeys: nil)
        }
    }

    override static public func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate? {
        let encryptedNotSynced = NSPredicate(format: "%K == FALSE", DeliveredKey)
        let notExpired = NSPredicate(format: "%K == 0", ZMMessageIsExpiredKey)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [encryptedNotSynced, notExpired])
    }

    public override func markAsSent() {
        super.markAsSent()

        if linkPreviewState == ZMLinkPreviewState.uploaded {
            linkPreviewState = ZMLinkPreviewState.done
        }
        setObfuscationTimerIfNeeded()
    }

    private func setObfuscationTimerIfNeeded() {
        guard isEphemeral else {
            return
        }
        if let genericMessage = self.underlyingMessage,
            genericMessage.textData != nil,
            !genericMessage.linkPreviews.isEmpty,
            linkPreviewState != ZMLinkPreviewState.done {
            // If we have link previews and they are not sent yet, we wait until they are sent
            return
        }
        startDestructionIfNeeded()
    }

    func hasDownloadedImage() -> Bool {
        guard
            let textMessageData = self.textMessageData,
            textMessageData.linkPreview != nil,
            let managedObjectContext = self.managedObjectContext else {
                return false
        }
        // processed or downloaded
        let hasMedium = managedObjectContext.zm_fileAssetCache.hasDataOnDisk(self, format: ZMImageFormat.medium, encrypted: false)

        // original
        let hasOriginal = managedObjectContext.zm_fileAssetCache.hasDataOnDisk(self, format: ZMImageFormat.original, encrypted: false)

        return hasMedium || hasOriginal
    }
}

extension ZMClientMessage {

    public override var imageMessageData: ZMImageMessageData? {
        return nil
    }

    public override var fileMessageData: ZMFileMessageData? {
        return nil
    }

    public override var isSilenced: Bool {
        return conversation?.isMessageSilenced(underlyingMessage, senderID: sender?.remoteIdentifier) ?? true
    }
}
