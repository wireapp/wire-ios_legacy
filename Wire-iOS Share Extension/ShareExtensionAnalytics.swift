//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import WireShareEngine
import WireExtensionComponents
import MobileCoreServices
import WireDataModel


class ExtensionActivity {

    static private var openedEventName = "share_extension_opened"
    static private var sentEventName = "share_extension_sent"
    static private var cancelledEventName = "share_extension_cancelled"

    private var verifiedConversation = false
    private var conversationDidDegrade = false
    private var numberOfImages = 0
    private var hasVideo = false
    private var hasFile = false
    public var hasText = false
    private let attachments: [NSItemProvider]

    public var conversation: Conversation? = nil {
        didSet {
            verifiedConversation = conversation?.isTrusted == true
        }
    }

    init(attachments: [NSItemProvider]) {
        self.attachments = attachments
    }

    func markConversationDidDegrade() {
        conversationDidDegrade = true
    }

    func openedEvent() -> StorableTrackingEvent {
        return StorableTrackingEvent(
            name: ExtensionActivity.openedEventName,
            attributes: [:]
        )
    }

    func cancelledEvent() -> StorableTrackingEvent {
        return StorableTrackingEvent(
            name: ExtensionActivity.cancelledEventName,
            attributes: [:]
        )
    }

    func sentEvent(completion: @escaping (StorableTrackingEvent) -> Void) {
        populateAttachmentTypes { [weak self] in
            guard let `self` = self else { return }
            let event = StorableTrackingEvent(
                name: ExtensionActivity.sentEventName,
                attributes: [
                    "verified_conversation": self.verifiedConversation,
                    "number_of_images": self.numberOfImages,
                    "video": self.hasVideo,
                    "file": self.hasFile,
                    "text": self.hasText,
                    "conversation_did_degrade": self.conversationDidDegrade
                ]
            )

            completion(event)
        }
    }

    func populateAttachmentTypes(completion: @escaping () -> Void) {
        hasVideo = attachments.contains { $0.hasVideo }
        numberOfImages = attachments.filter { $0.hasImage }.count

        let group = DispatchGroup()
        attachments.forEach { _ in
            group.enter()
        }

        attachments.forEach {
            $0.hasFile { [weak self] in
                guard let `self` = self else { return }
                self.hasFile = self.hasFile || $0
                group.leave()
            }
        }

        group.notify(queue: .main) { 
            completion()
        }
    }

}


extension NSItemProvider {

    var hasImage: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeImage as String)
    }

    func hasFile(completion: @escaping (Bool) -> Void) {
        guard !hasImage && !hasVideo && !hasWalletPass else { return completion(false) }
        if hasURL {
            fetchURL { [weak self] url in
                if (url != nil && !url!.isFileURL) || self?.hasData == false {
                    return completion(false)
                }
                completion(true)
            }
        } else {
            completion(hasData)
        }
    }

    private var hasData: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeData as String)
    }

    var hasURL: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeURL as String)
    }

    var hasVideo: Bool {
        guard let uti = registeredTypeIdentifiers.first as? String else { return false }
        return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
    }
    
    var hasWalletPass: Bool {
        return hasItemConformingToTypeIdentifier("com.apple.pkpass")
    }
}
