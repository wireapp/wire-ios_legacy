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

private var zmLog = ZMSLog(tag: "MessageChangeInfo")

// MARK: Message observing 

enum MessageKey: String {
    case previewGenericMessage
    case mediumGenericMessage
    case linkPreview
    case underlyingMessage
}

extension ZMMessage: ObjectInSnapshot {

    @objc public class var observableKeys: Set<String> {
        return [#keyPath(ZMMessage.deliveryState), #keyPath(ZMMessage.isObfuscated)]
    }

    public var notificationName: Notification.Name {
        return .MessageChange
    }
}

extension ZMAssetClientMessage {

    public class override var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [#keyPath(ZMAssetClientMessage.transferState),
                              MessageKey.previewGenericMessage.rawValue,
                              MessageKey.mediumGenericMessage.rawValue,
                              #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
                              #keyPath(ZMAssetClientMessage.hasDownloadedFile),
                              #keyPath(ZMAssetClientMessage.isDownloading),
                              #keyPath(ZMAssetClientMessage.progress),
                              #keyPath(ZMMessage.reactions),
                              #keyPath(ZMMessage.confirmations)]
        return keys.union(additionalKeys)
    }
}

extension ZMClientMessage {

    public class override var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [#keyPath(ZMAssetClientMessage.hasDownloadedPreview),
                              #keyPath(ZMClientMessage.linkPreviewState),
                              MessageKey.underlyingMessage.rawValue,
                              #keyPath(ZMMessage.reactions),
                              #keyPath(ZMMessage.confirmations),
                              #keyPath(ZMClientMessage.quote),
                              MessageKey.linkPreview.rawValue,
                              #keyPath(ZMMessage.linkAttachments),
                              #keyPath(ZMClientMessage.buttonStates)]
        return keys.union(additionalKeys)
    }
}

extension ZMImageMessage {

    public class override var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [#keyPath(ZMImageMessage.mediumData),
                              #keyPath(ZMImageMessage.mediumRemoteIdentifier),
                              #keyPath(ZMMessage.reactions)]
        return keys.union(additionalKeys)
    }
}

extension ZMSystemMessage {

    public class override var observableKeys: Set<String> {
        let keys = super.observableKeys
        let additionalKeys = [#keyPath(ZMSystemMessage.childMessages),
                              #keyPath(ZMSystemMessage.systemMessageType)]
        return keys.union(additionalKeys)
    }

}

@objcMembers final public class MessageChangeInfo: ObjectChangeInfo {

    static let UserChangeInfoKey = "userChanges"
    static let ReactionChangeInfoKey = "reactionChanges"
    static let ButtonStateChangeInfoKey = "buttonStateChanges"

    static func changeInfo(for message: ZMMessage, changes: Changes) -> MessageChangeInfo? {
        return MessageChangeInfo(object: message, changes: changes)
    }

    public required init(object: NSObject) {
        self.message = object as! ZMMessage
        super.init(object: object)
    }

    public override var debugDescription: String {
        return ["deliveryStateChanged: \(deliveryStateChanged)",
                "reactionsChanged: \(reactionsChanged)",
                "confirmationsChanged: \(confirmationsChanged)",
                "childMessagesChanged: \(childMessagesChanged)",
                "quoteChanged: \(quoteChanged)",
                "imageChanged: \(imageChanged)",
                "fileAvailabilityChanged: \(fileAvailabilityChanged)",
                "usersChanged: \(usersChanged)",
                "linkPreviewChanged: \(linkPreviewChanged)",
                "transferStateChanged: \(transferStateChanged)",
                "senderChanged: \(senderChanged)",
                "isObfuscatedChanged: \(isObfuscatedChanged)",
                "underlyingMessageChanged: \(underlyingMessageChanged)",
                "linkAttachmentsChanged: \(linkAttachmentsChanged)",
                "buttonStatesChanged: \(buttonStatesChanged)"
                ].joined(separator: ", ")
    }

    public var deliveryStateChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMMessage.deliveryState))
    }

    public var reactionsChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMMessage.reactions)) ||
               changeInfos[MessageChangeInfo.ReactionChangeInfoKey] != nil
    }

    public var confirmationsChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMMessage.confirmations))
    }

    public var underlyingMessageChanged: Bool {
        return changedKeysContain(keys: MessageKey.underlyingMessage.rawValue)
    }

    public var childMessagesChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMSystemMessage.childMessages))
    }

    public var quoteChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMClientMessage.quote))
    }

    /// Whether the image data on disk changed
    public var imageChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMImageMessage.mediumData),
                                  #keyPath(ZMImageMessage.mediumRemoteIdentifier),
                                  #keyPath(ZMAssetClientMessage.hasDownloadedPreview),
                                  #keyPath(ZMAssetClientMessage.hasDownloadedFile),
                                  MessageKey.previewGenericMessage.rawValue,
                                  MessageKey.mediumGenericMessage.rawValue)
    }

    /// Whether the file on disk changed
    public var fileAvailabilityChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMAssetClientMessage.hasDownloadedFile))
    }

    public var usersChanged: Bool {
        return userChangeInfo != nil
    }

    public var linkPreviewChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMClientMessage.linkPreviewState), MessageKey.linkPreview.rawValue)
    }

    public var transferStateChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMAssetClientMessage.transferState))
    }

    public var senderChanged: Bool {
        if self.usersChanged && (self.userChangeInfo?.user as? ZMUser ==  self.message.sender) {
            return true
        }
        return false
    }

    public var isObfuscatedChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMMessage.isObfuscated))
    }

    public var linkAttachmentsChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMMessage.linkAttachments))
    }

    public var buttonStatesChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMClientMessage.buttonStates)) || changeInfos[MessageChangeInfo.ButtonStateChangeInfoKey] != nil
    }

    public var userChangeInfo: UserChangeInfo? {
        return changeInfos[MessageChangeInfo.UserChangeInfoKey] as? UserChangeInfo
    }

    public let message: ZMMessage

}

@objc public protocol ZMMessageObserver: NSObjectProtocol {
    func messageDidChange(_ changeInfo: MessageChangeInfo)
}

extension MessageChangeInfo {

    /// Adds a ZMMessageObserver to the specified message
    /// To observe messages and their users (senders, systemMessage users), observe the conversation window instead
    /// Messages observed with this call will not contain information about user changes
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forMessage:managedObjectContext:)
    public static func add(observer: ZMMessageObserver,
                           for message: ZMConversationMessage,
                           managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .MessageChange,
                                          managedObjectContext: managedObjectContext,
                                          object: message) { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? MessageChangeInfo
                else { return }

            observer.messageDidChange(changeInfo)
        }
    }
}
