//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

private let log = ZMSLog(tag: "Conversations")

extension ZMConversation {

    /// An error describing why a message couldn't be appended to the conversation.

    public enum AppendMessageError: LocalizedError, Equatable {

        case missingManagedObjectContext
        case malformedNonce
        case failedToProcessMessageData(reason: String)
        case messageIsEmpty
        case failedToRemoveImageMetadata
        case invalidImageUrl
        case invalidFileUrl
        case fileSharingIsRestricted

        public var errorDescription: String? {
            switch self {
            case .missingManagedObjectContext:
                return "The managed object context is missing."
            case .malformedNonce:
                return "Encountered a malformed nonce."
            case .failedToProcessMessageData(let reason):
                return "Failed to process generic message data. Reason: \(reason)"
            case .messageIsEmpty:
                return "Can not send empty text messages."
            case .failedToRemoveImageMetadata:
                return "Failed to remove image metatdata."
            case .invalidImageUrl:
                return "Invalid image url."
            case .invalidFileUrl:
                return "Invalid file url."
            case .fileSharingIsRestricted:
                return "File sharing is restricted."
            }
        }

    }

    /// Appends a button action message.
    ///
    /// - Parameters:
    ///     - id: The id of the button action.
    ///     - referenceMessageId: The id of the message which this action references.
    ///     - nonce: The nonce of the button action message.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    func appendButtonAction(havingId id: String, referenceMessageId: UUID, nonce: UUID = UUID()) throws -> ZMClientMessage {
        let buttonAction = ButtonAction(buttonId: id, referenceMessageId: referenceMessageId)
        return try appendClientMessage(with: GenericMessage(content: buttonAction, nonce: nonce), hidden: true)
    }

    /// Appends a location message.
    ///
    /// - Parameters:
    ///     - locationData: The data describing the location.
    ///     - nonce: The nonce of the location message.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public func appendLocation(with locationData: LocationData, nonce: UUID = UUID()) throws -> ZMConversationMessage {
        let locationContent = Location.with {
            if let name = locationData.name {
                $0.name = name
            }

            $0.latitude = locationData.latitude
            $0.longitude = locationData.longitude
            $0.zoom = locationData.zoomLevel
        }

        let message = GenericMessage(content: locationContent, nonce: nonce, expiresAfter: activeMessageDestructionTimeoutValue)
        return try appendClientMessage(with: message)
    }

    /// Appends a knock message.
    ///
    /// - Parameters:
    ///     - nonce: The nonce of the knock message.
    ///
    /// - Throws:
    ///     `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public func appendKnock(nonce: UUID = UUID()) throws -> ZMConversationMessage {
        let content = Knock.with { $0.hotKnock = false }
        let message = GenericMessage(content: content, nonce: nonce, expiresAfter: activeMessageDestructionTimeoutValue)
        return try appendClientMessage(with: message)
    }

    /// Appends a text message.
    ///
    /// - Parameters:
    ///     - content: The message content.
    ///     - mentions: The list of mentioned participants.
    ///     - quotedMessage: The message being replied to.
    ///     - fetchLinkPreview: Whether link previews should be fetched.
    ///     - nonce: The nonce of the message.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public func appendText(content: String,
                           mentions: [Mention] = [],
                           replyingTo quotedMessage: ZMConversationMessage? = nil,
                           fetchLinkPreview: Bool = true,
                           nonce: UUID = UUID()) throws -> ZMConversationMessage {

        guard !(content as NSString).zmHasOnlyWhitespaceCharacters() else {
            throw AppendMessageError.messageIsEmpty
        }

        let text = Text(content: content, mentions: mentions, linkPreviews: [], replyingTo: quotedMessage as? ZMOTRMessage)
        let genericMessage = GenericMessage(content: text, nonce: nonce, expiresAfter: activeMessageDestructionTimeoutValue)

        let clientMessage = try appendClientMessage(with: genericMessage, expires: true, hidden: false, configure: {
            $0.linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
            $0.needsLinkAttachmentsUpdate = fetchLinkPreview
            $0.quote = quotedMessage as? ZMMessage
        })

        if let notificationContext = managedObjectContext?.notificationContext {
            NotificationInContext(name: ZMConversation.clearTypingNotificationName,
                                  context: notificationContext,
                                  object: self).post()
        }

        return clientMessage
    }

    /// Append an image message.
    ///
    /// - Parameters:
    ///     - url: A url locating some image data.
    ///     - nonce: The nonce of the message.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public func appendImage(at URL: URL, nonce: UUID = UUID()) throws -> ZMConversationMessage {
        guard
            URL.isFileURL,
            ZMImagePreprocessor.sizeOfPrerotatedImage(at: URL) != .zero,
            let imageData = try? Data.init(contentsOf: URL, options: [])
        else {
            throw AppendMessageError.invalidImageUrl
        }

        return try appendImage(from: imageData)
    }

    /// Append an image message.
    ///
    /// - Parameters:
    ///     - imageData: Data representing an image.
    ///     - nonce: The nonce of the message.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public func appendImage(from imageData: Data, nonce: UUID = UUID()) throws -> ZMConversationMessage {
        guard let moc = managedObjectContext else {
            throw AppendMessageError.missingManagedObjectContext
        }

        guard let imageData = try? imageData.wr_removingImageMetadata() else {
            throw AppendMessageError.failedToRemoveImageMetadata
        }

        // mimeType is assigned first, to make sure UI can handle animated GIF file correctly.
        let mimeType = imageData.mimeType ?? ""

        // We update the size again when the the preprocessing is done.
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)

        let asset = WireProtos.Asset(imageSize: imageSize,
                                     mimeType: mimeType,
                                     size: UInt64(imageData.count))

        return try append(asset: asset, nonce: nonce, expires: true, prepareMessage: { message in
            moc.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: imageData)
        })
    }

    /// Append a file message.
    ///
    /// - Parameters:
    ///     - fileMetadata: Data describing the file.
    ///     - nonce: The nonce of the message.
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.
    ///
    /// - Returns:
    ///     The appended message.

    @discardableResult
    public func appendFile(with fileMetadata: ZMFileMetadata, nonce: UUID = UUID()) throws -> ZMConversationMessage {
        guard let moc = managedObjectContext else {
            throw AppendMessageError.missingManagedObjectContext
        }

        guard let data = try? Data.init(contentsOf: fileMetadata.fileURL, options: .mappedIfSafe) else {
            throw AppendMessageError.invalidFileUrl
        }

        return try append(asset: fileMetadata.asset, nonce: nonce, expires: false) { (message) in
            moc.zm_fileAssetCache.storeAssetData(message, encrypted: false, data: data)

            if let thumbnailData = fileMetadata.thumbnail {
                moc.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: thumbnailData)
            }
        }
    }

    private func append(asset: WireProtos.Asset,
                        nonce: UUID,
                        expires: Bool,
                        prepareMessage: (ZMAssetClientMessage) -> Void) throws -> ZMAssetClientMessage {

        guard let moc = managedObjectContext else {
            throw AppendMessageError.missingManagedObjectContext
        }

        let message: ZMAssetClientMessage

        do {
            message = try ZMAssetClientMessage(asset: asset,
                                               nonce: nonce,
                                               managedObjectContext: moc,
                                               expiresAfter: activeMessageDestructionTimeoutValue?.rawValue)
        } catch {
            throw AppendMessageError.failedToProcessMessageData(reason: error.localizedDescription)
        }

        guard !message.isRestricted else {
            throw AppendMessageError.fileSharingIsRestricted
        }

        message.sender = ZMUser.selfUser(in: moc)

        if expires {
            message.setExpirationDate()
        }

        append(message)
        unarchiveIfNeeded()
        prepareMessage(message)
        message.updateCategoryCache()
        message.prepareToSend()

        return message
    }

    /// Appends a new message to the conversation.
    ///
    /// - Parameters:
    ///     - genericMessage: The generic message that should be appended.
    ///     - expires: Whether the message should expire or tried to be send infinitively.
    ///     - hidden: Whether the message should be hidden in the conversation or not
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.

    @discardableResult
    public func appendClientMessage(with genericMessage: GenericMessage,
                                    expires: Bool = true,
                                    hidden: Bool = false,
                                    configure: ((ZMClientMessage) -> Void)? = nil) throws -> ZMClientMessage {

        guard let moc = managedObjectContext else {
            throw AppendMessageError.missingManagedObjectContext
        }

        guard let nonce = UUID(uuidString: genericMessage.messageID) else {
            throw AppendMessageError.malformedNonce
        }

        let message = ZMClientMessage(nonce: nonce, managedObjectContext: moc)
        configure?(message)

        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            moc.delete(message)
            throw AppendMessageError.failedToProcessMessageData(reason: error.localizedDescription)
        }

        do {
            try append(message, expires: expires, hidden: hidden)
        } catch {
            moc.delete(message)
            throw error
        }

        return message
    }

    /// Appends a new message to the conversation.
    ///
    /// - Parameters:
    ///     - message: The message that should be appended.
    ///     - expires: Whether the message should expire or tried to be send infinitively.
    ///     - hidden: Whether the message should be hidden in the conversation or not
    ///
    /// - Throws:
    ///     - `AppendMessageError` if the message couldn't be appended.

    private func append(_ message: ZMClientMessage, expires: Bool, hidden: Bool) throws {
        guard let moc = managedObjectContext else {
            throw AppendMessageError.missingManagedObjectContext
        }

        message.sender = ZMUser.selfUser(in: moc)

        if expires {
            message.setExpirationDate()
        }

        if hidden {
            message.hiddenInConversation = self
        } else {
            append(message)
            unarchiveIfNeeded()
            message.updateCategoryCache()
            message.prepareToSend()
        }
    }

}

@objc
extension ZMConversation {

    // MARK: - Objective-C compability methods

    @discardableResult @objc(appendMessageWithText:)
    public func _appendText(content: String) -> ZMConversationMessage? {
        return try? appendText(content: content)
    }

    @discardableResult @objc(appendMessageWithText:fetchLinkPreview:)
    public func _appendText(content: String, fetchLinkPreview: Bool) -> ZMConversationMessage? {
        return try? appendText(content: content, fetchLinkPreview: fetchLinkPreview)
    }

    @discardableResult @objc(appendText:mentions:fetchLinkPreview:nonce:)
    public func _appendText(content: String,
                            mentions: [Mention],
                            fetchLinkPreview: Bool,
                            nonce: UUID) -> ZMConversationMessage? {

        return try? appendText(content: content,
                               mentions: mentions,
                               fetchLinkPreview: fetchLinkPreview,
                               nonce: nonce)
    }

    @discardableResult @objc(appendText:mentions:replyingToMessage:fetchLinkPreview:nonce:)
    public func _appendText(content: String,
                            mentions: [Mention],
                            replyingTo quotedMessage: ZMConversationMessage?,
                            fetchLinkPreview: Bool,
                            nonce: UUID) -> ZMConversationMessage? {

        return try? appendText(content: content,
                               mentions: mentions,
                               replyingTo: quotedMessage,
                               fetchLinkPreview: fetchLinkPreview,
                               nonce: nonce)
    }

    @discardableResult @objc(appendKnock)
    public func _appendKnock() -> ZMConversationMessage? {
        return try? appendKnock()
    }

    @discardableResult @objc(appendMessageWithLocationData:)
    public func _appendLocation(with locationData: LocationData) -> ZMConversationMessage? {
        return try? appendLocation(with: locationData)
    }

    @discardableResult @objc(appendMessageWithImageData:)
    public func _appendImage(from imageData: Data) -> ZMConversationMessage? {
        return try? appendImage(from: imageData)
    }

    @discardableResult @objc(appendImageFromData:nonce:)
    public func _appendImage(from imageData: Data, nonce: UUID) -> ZMConversationMessage? {
        return try? appendImage(from: imageData, nonce: nonce)
    }

    @discardableResult @objc(appendImageAtURL:nonce:)
    public func _appendImage(at URL: URL, nonce: UUID) -> ZMConversationMessage? {
        return try? appendImage(at: URL, nonce: nonce)
    }

    @discardableResult @objc(appendMessageWithFileMetadata:)
    public func _appendFile(with fileMetadata: ZMFileMetadata) -> ZMConversationMessage? {
        return try? appendFile(with: fileMetadata)
    }

    @discardableResult @objc(appendFile:nonce:)
    public func _appendFile(with fileMetadata: ZMFileMetadata, nonce: UUID) -> ZMConversationMessage? {
        return try? appendFile(with: fileMetadata, nonce: nonce)
    }

}
