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
import WireProtos

// MARK: - GenericMessage

public extension GenericMessage {
    init?(withBase64String base64String: String?) {
        guard
            let string = base64String,
            let data = Data(base64Encoded: string),
            let message = GenericMessage.with({ try? $0.merge(serializedData: data) }).validatingFields()
        else { return nil }
        self = message
    }

    init(content: EphemeralMessageCapable, nonce: UUID = UUID(), expiresAfter timeout: MessageDestructionTimeoutValue? = nil) {
        self.init(content: content, nonce: nonce, expiresAfterTimeInterval: timeout?.rawValue)
    }

    init(content: EphemeralMessageCapable, nonce: UUID = UUID(), expiresAfterTimeInterval timeout: TimeInterval? = nil) {
        self = GenericMessage.with {
            $0.messageID = nonce.transportString()
            let messageContent: MessageCapable
            if let timeout = timeout, timeout > 0 {
                messageContent = Ephemeral(content: content, expiresAfter: timeout)
            } else {
                messageContent = content
            }
            messageContent.setContent(on: &$0)
        }
    }

    init(content: MessageCapable, nonce: UUID = UUID()) {
        self = GenericMessage.with {
            $0.messageID = nonce.transportString()
            let messageContent = content
            messageContent.setContent(on: &$0)
        }
    }

    init(clientAction action: ClientAction, nonce: UUID = UUID()) {
        self = GenericMessage.with {
            $0.messageID = nonce.transportString()
            $0.clientAction = action
        }
    }
}

extension GenericMessage {
    public var messageData: MessageCapable? {
        guard let content = content else { return nil }
        switch content {
        case .text(let data):
            return data
        case .confirmation(let data):
            return data
        case .reaction(let data):
            return data
        case .asset(let data):
            return data
        case .ephemeral(let data):
            return data.messageData
        case .clientAction(let data):
            return data
        case .cleared(let data):
            return data
        case .lastRead(let data):
            return data
        case .knock(let data):
            return data
        case .external(let data):
            return data
        case .availability(let data):
            return data
        case .edited(let data):
            return data
        case .deleted(let data):
            return data
        case .calling(let data):
            return data
        case .hidden(let data):
            return data
        case .location(let data):
            return data
        case .image(let data):
            return data
        case .composite(let data):
            return data
        case .buttonAction(let data):
            return data
        case .buttonActionConfirmation(let data):
            return data
        case .dataTransfer(let data):
            return data
        }
    }

    var locationData: Location? {
        guard let content = content else { return nil }
        switch content {
        case .location(let data):
            return data
        case .ephemeral(let data):
            switch data.content {
            case .location(let data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    public var compositeData: Composite? {
        guard let content = content else { return nil }
        switch content {
        case .composite(let data):
            return data
        default:
            return nil
        }
    }

    public var imageAssetData: ImageAsset? {
        guard let content = content else { return nil }
        switch content {
        case .image(let data):
            return data
        case .ephemeral(let data):
            switch data.content {
            case .image(let data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    public var assetData: WireProtos.Asset? {
        guard let content = content else { return nil }
        switch content {
        case .asset(let data):
            return data
        case .ephemeral(let data):
            switch data.content {
            case .asset(let data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    public var knockData: Knock? {
        guard let content = content else { return nil }
        switch content {
        case .knock(let data):
            return data
        case .ephemeral(let data):
            switch data.content {
            case .knock(let data)?:
                return data
            default:
                return nil
            }
        default:
            return nil
        }
    }

    public var textData: Text? {
        guard let content = content else { return nil }
        switch content {
        case .text(let data):
            return data
        case .edited(let messageEdit):
            if case .text(let data)? = messageEdit.content {
                return data
            }
        case .ephemeral(let ephemeral):
            if case .text(let data)? = ephemeral.content {
                return data
            }
        default:
            return nil
        }
        return nil
    }
}

public extension Text {
    func isMentioningSelf(_ selfUser: ZMUser) -> Bool {
        return mentions.any {$0.userID.uppercased() == selfUser.remoteIdentifier.uuidString }
    }

    func isQuotingSelf(_ quotedMessage: ZMOTRMessage?) -> Bool {
        return quotedMessage?.sender?.isSelfUser ?? false
    }
}

extension GenericMessage {
    var v3_isImage: Bool {
        return assetData?.original.hasRasterImage ?? false
    }

    var v3_uploadedAssetId: String? {
        guard
            let assetData = assetData,
            case .uploaded? = assetData.status
        else {
            return nil
        }
        return assetData.uploaded.assetID
    }

    public var previewAssetId: String? {
        guard
            let assetData = assetData,
            assetData.hasPreview,
            assetData.preview.hasRemote,
            assetData.preview.remote.hasAssetID
        else {
            return nil
        }
        return assetData.preview.remote.assetID
    }
}

extension GenericMessage {
    public var linkPreviews: [LinkPreview] {
        guard let content = content else { return [] }
        switch content {
        case .text:
            return text.linkPreview.compactMap { $0 }
        case .edited:
            return edited.text.linkPreview.compactMap { $0 }
        case .ephemeral(let ephemeral):
            if case .text? = ephemeral.content {
                return ephemeral.text.linkPreview.compactMap { $0 }
            } else {
                return []
            }
        default:
            return []
        }
    }
}

// MARK: - Ephemeral

extension Ephemeral {
    public init(content: EphemeralMessageCapable, expiresAfter timeout: TimeInterval) {
        self = Ephemeral.with {
            $0.expireAfterMillis = Int64(timeout * 1000)
            content.setEphemeralContent(on: &$0)
        }
    }

    public var messageData: MessageCapable? {
        guard let content = content else { return nil }
        switch content {
        case .text(let data):
            return data
        case .asset(let data):
            return data
        case .knock(let data):
            return data
        case .location(let data):
            return data
        case .image(let data):
            return data
        }
    }
}

public extension Proteus_QualifiedUserId {
    init(with uuid: UUID, domain: String) {
        self = Proteus_QualifiedUserId.with {
            $0.id = uuid.transportString()
            $0.domain = domain
        }
    }
}

// MARK: - ClientEntry

public extension Proteus_ClientEntry {
    init(withClient client: UserClient, data: Data) {
        self = Proteus_ClientEntry.with {
            $0.client = client.clientId
            $0.text = data
        }
    }
}

// MARK: - QualifiedUserEntry

public extension Proteus_QualifiedUserEntry {
    init(withDomain domain: String, userEntries: [Proteus_UserEntry]) {
        self = Proteus_QualifiedUserEntry.with {
            $0.domain = domain
            $0.entries = userEntries
        }
    }
}

// MARK: - UserEntry

public extension Proteus_UserEntry {
    init(withUser user: ZMUser, clientEntries: [Proteus_ClientEntry]) {
        self = Proteus_UserEntry.with {
            $0.user = user.userId
            $0.clients = clientEntries
        }
    }
}

// MARK: - QualifiedNewOtrMessage

public extension Proteus_QualifiedNewOtrMessage {
    init(withSender sender: UserClient,
         nativePush: Bool,
         recipients: [Proteus_QualifiedUserEntry],
         missingClientsStrategy: MissingClientsStrategy,
         blob: Data? = nil ) {

        self = Proteus_QualifiedNewOtrMessage.with {
            $0.nativePush = nativePush
            $0.sender = sender.clientId
            $0.recipients = recipients

            if let blob = blob {
                $0.blob = blob
            }

            switch missingClientsStrategy {
            case .doNotIgnoreAnyMissingClient:
                $0.clientMismatchStrategy = .reportAll(.init())
            case .ignoreAllMissingClients:
                $0.clientMismatchStrategy = .ignoreAll(.init())
            case .ignoreAllMissingClientsNotFromUsers(users: let users):
                $0.clientMismatchStrategy = .reportOnly(.with({
                    $0.userIds = users.compactMap({
                        guard
                            let uuid = $0.remoteIdentifier,
                            let domain = $0.domain
                        else {
                            return nil
                        }

                        return Proteus_QualifiedUserId(with: uuid, domain: domain)
                    })
                }))
            }
        }
    }
}

// MARK: - NewOtrMessage

public extension Proteus_NewOtrMessage {
    init(withSender sender: UserClient, nativePush: Bool, recipients: [Proteus_UserEntry], blob: Data? = nil) {
        self = Proteus_NewOtrMessage.with {
            $0.nativePush = nativePush
            $0.sender = sender.clientId
            $0.recipients = recipients
            if blob != nil {
                $0.blob = blob!
            }
        }
    }
}

// MARK: - ButtonAction

extension ButtonAction {
    init(buttonId: String, referenceMessageId: UUID) {
        self = ButtonAction.with {
            $0.buttonID = buttonId
            $0.referenceMessageID = referenceMessageId.transportString()
        }
    }
}

// MARK: - Location

extension Location {
    init(latitude: Float, longitude: Float) {
        self = WireProtos.Location.with {
            $0.latitude = latitude
            $0.longitude = longitude
        }
    }
}

// MARK: - Text

extension Text {
    public init(content: String, mentions: [Mention] = [], linkPreviews: [LinkMetadata] = [], replyingTo: ZMOTRMessage? = nil) {
        self = Text.with {
            $0.content = content
            $0.mentions = mentions.compactMap { WireProtos.Mention.createMention($0) }
            $0.linkPreview = linkPreviews.map { WireProtos.LinkPreview($0) }

            if let quotedMessage = replyingTo,
               let quotedMessageNonce = quotedMessage.nonce,
               let quotedMessageHash = quotedMessage.hashOfContent {
                $0.quote = Quote.with {
                    $0.quotedMessageID = quotedMessageNonce.transportString()
                    $0.quotedMessageSha256 = quotedMessageHash
                }
            }
        }
    }

    public func applyEdit(from text: Text) -> Text {
        var updatedText = text
        // Transfer read receipt expectation
        updatedText.expectsReadConfirmation = expectsReadConfirmation

        // We always keep the quote from the original message
        hasQuote
            ? updatedText.quote = quote
            : updatedText.clearQuote()
        return updatedText
    }

    public func updateLinkPreview(from text: Text) -> Text {
        guard !text.linkPreview.isEmpty else {
            return self
        }
        do {
            let data = try serializedData()
            var updatedText = try Text(serializedData: data)
            updatedText.linkPreview = text.linkPreview
            return updatedText
        } catch {
            return self
        }
    }
}

// MARK: - Reaction

extension WireProtos.Reaction {
    public static func createReaction(emoji: String, messageID: UUID) -> WireProtos.Reaction {
        return WireProtos.Reaction.with({
            $0.emoji = emoji
            $0.messageID = messageID.transportString()
        })
    }
}

public enum ProtosReactionFactory {
    public static func createReaction(emoji: String, messageID: UUID) -> WireProtos.Reaction {
        return WireProtos.Reaction.createReaction(emoji: emoji,
                                                  messageID: messageID)
    }
}

// MARK: - LastRead

extension LastRead {
    public init(conversationID: UUID, lastReadTimestamp: Date) {
        self = LastRead.with {
            $0.conversationID = conversationID.transportString()
            $0.lastReadTimestamp = Int64(lastReadTimestamp.timeIntervalSince1970 * 1000)
        }
    }
}

// MARK: - Calling

extension Calling {
    public init(content: String) {
        self = Calling.with {
            $0.content = content
        }
    }
}

// MARK: - MessageEdit

extension WireProtos.MessageEdit {
    public init(replacingMessageID: UUID, text: Text) {
        self = MessageEdit.with {
            $0.replacingMessageID = replacingMessageID.transportString()
            $0.text = text
        }
    }
}

// MARK: - Cleared

extension Cleared {
    public init(timestamp: Date, conversationID: UUID) {
        self = Cleared.with {
            $0.clearedTimestamp = Int64(timestamp.timeIntervalSince1970 * 1000)
            $0.conversationID = conversationID.transportString()
        }
    }
}

// MARK: - MessageHide

extension MessageHide {
    public init(conversationId: UUID, messageId: UUID) {
        self = MessageHide.with {
            $0.conversationID = conversationId.transportString()
            $0.messageID = messageId.transportString()
        }
    }
}

// MARK: - MessageDelete

extension MessageDelete {
    public init(messageId: UUID) {
        self = MessageDelete.with {
         $0.messageID = messageId.transportString()
        }
    }
}

// MARK: - Confirmation

extension WireProtos.Confirmation {
    public init?(messageIds: [UUID], type: Confirmation.TypeEnum = .delivered) {
        guard let firstMessageID = messageIds.first else {
            return nil
        }
        let moreMessageIds = Array(messageIds.dropFirst())
        self = WireProtos.Confirmation.with({
            $0.firstMessageID = firstMessageID.transportString()
            $0.moreMessageIds = moreMessageIds.map { $0.transportString() }
            $0.type = type
        })
    }

    public init(messageId: UUID, type: Confirmation.TypeEnum = .delivered) {
        self = WireProtos.Confirmation.with {
            $0.firstMessageID = messageId.transportString()
            $0.type = type
        }
    }
}

// MARK: - External

extension External {
    init(withOTRKey otrKey: Data, sha256: Data) {
        self = External.with {
            $0.otrKey = otrKey
            $0.sha256 = sha256
        }
    }

    init(withKeyWithChecksum key: ZMEncryptionKeyWithChecksum) {
        self = External(withOTRKey: key.aesKey, sha256: key.sha256)
    }
}

// MARK: - Mention
public extension WireProtos.Mention {
    static func createMention(_ mention: WireDataModel.Mention) -> WireProtos.Mention? {
        return mention.convertToProtosMention()
    }
}

public extension WireDataModel.Mention {
    func convertToProtosMention() -> WireProtos.Mention? {
        guard let userID = (user as? ZMUser)?.remoteIdentifier.transportString() else { return nil }

        return WireProtos.Mention.with {
            $0.start = Int32(range.location)
            $0.length = Int32(range.length)
            $0.userID = userID

            guard let domain = user.domain else { return }

            $0.qualifiedUserID =  WireProtos.QualifiedUserId.with {
                $0.id = userID
                $0.domain = domain
            }
        }
    }
}

// MARK: - Availability

extension WireProtos.Availability {
    public init(_ availability: AvailabilityKind) {
        self = WireProtos.Availability.with {
            switch availability {
            case .none:
                $0.type = .none
            case .available:
                $0.type = .available
            case .away:
                $0.type = .away
            case .busy:
                $0.type = .busy
            }
        }
    }
}

// MARK: - LinkPreview

public extension LinkPreview {
    init(_ linkMetadata: LinkMetadata) {
        if let articleMetadata = linkMetadata as? ArticleMetadata {
            self = LinkPreview(articleMetadata: articleMetadata)
        } else if let twitterMetadata = linkMetadata as? TwitterStatusMetadata {
            self = LinkPreview(twitterMetadata: twitterMetadata)
        } else {
            self = LinkPreview.with {
                $0.url = linkMetadata.originalURLString
                $0.permanentURL = linkMetadata.permanentURL?.absoluteString ?? linkMetadata.resolvedURL?.absoluteString ?? linkMetadata.originalURLString
                $0.urlOffset = Int32(linkMetadata.characterOffsetInText)
            }
        }
    }

    init(articleMetadata: ArticleMetadata) {
        self = LinkPreview.with {
            $0.url = articleMetadata.originalURLString
            $0.permanentURL = articleMetadata.permanentURL?.absoluteString ?? articleMetadata.resolvedURL?.absoluteString ?? articleMetadata.originalURLString
            $0.urlOffset = Int32(articleMetadata.characterOffsetInText)
            $0.title = articleMetadata.title ?? ""
            $0.summary = articleMetadata.summary ?? ""
            if let imageData = articleMetadata.imageData.first {
                $0.image = WireProtos.Asset(imageSize: CGSize(width: 0, height: 0), mimeType: "image/jpeg", size: UInt64(imageData.count))
            }
        }
    }

    init(twitterMetadata: TwitterStatusMetadata) {
        self = LinkPreview.with {
            $0.url = twitterMetadata.originalURLString
            $0.permanentURL = twitterMetadata.permanentURL?.absoluteString ?? twitterMetadata.resolvedURL?.absoluteString ?? twitterMetadata.originalURLString
            $0.urlOffset = Int32(twitterMetadata.characterOffsetInText)
            $0.title = twitterMetadata.message ?? ""
            if let imageData = twitterMetadata.imageData.first {
                $0.image = WireProtos.Asset(imageSize: CGSize(width: 0, height: 0), mimeType: "image/jpeg", size: UInt64(imageData.count))
            }

            guard let author = twitterMetadata.author,
                let username = twitterMetadata.username else { return }

            $0.tweet = WireProtos.Tweet.with({
                $0.author = author
                $0.username = username
            })
        }
    }

    init(withOriginalURL originalURL: String,
         permanentURL: String,
         offset: Int32,
         title: String?,
         summary: String?,
         imageAsset: WireProtos.Asset?,
         article: Article? = nil,
         tweet: Tweet? = nil) {
        self = LinkPreview.with {
            $0.url = originalURL
            $0.permanentURL = permanentURL
            $0.urlOffset = offset

            if let title = title {
                $0.title = title
            }
            if let summary = summary {
                $0.summary = summary
            }
            if let image = imageAsset {
                $0.image = image
            }
            if let tweet = tweet {
                $0.tweet = tweet
            }
            if let article = article {
                $0.article = article
            }
        }
    }

    mutating func update(withOtrKey otrKey: Data, sha256: Data, original: WireProtos.Asset.Original?) {
        image.uploaded = WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256)
        if let original = original {
            image.original = original
        }
    }

    mutating func update(withAssetKey assetKey: String, assetToken: String?, assetDomain: String?) {
        image.uploaded.assetID = assetKey
        image.uploaded.assetToken = assetToken ?? ""
        image.uploaded.assetDomain = assetDomain ?? ""
    }

    var hasTweet: Bool {
        switch metaData {
        case .tweet:
            return true
        default:
            return false
        }
    }
}

public extension Tweet {
    init(author: String?, username: String?) {
        self = Tweet.with {
            if let author = author {
                $0.author = author
            }
            if let username = username {
                $0.username = username
            }
        }
    }
}

// MARK: - ImageAsset

extension ImageAsset {
    public func imageFormat() -> ZMImageFormat {
        return ImageFormatFromString(self.tag)
    }
}

// MARK: - DataTransfer

extension DataTransfer {
    init(trackingIdentifier: UUID) {
        self = DataTransfer.with {
            $0.trackingIdentifier = TrackingIdentifier(trackingIdentifier)
        }
    }

    var trackingIdentifierData: String? {
        guard
            hasTrackingIdentifier,
            trackingIdentifier.hasIdentifier
        else {
            return nil
        }

        return trackingIdentifier.identifier
    }
}

// MARK: - TrackingIdentifier

extension TrackingIdentifier {
    init(_ uuid: UUID) {
        self = TrackingIdentifier.with {
            $0.identifier = uuid.transportString()
        }
    }
}
