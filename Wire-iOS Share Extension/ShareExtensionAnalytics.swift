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


class ExtensionActivity {

    private var eventName = "share_extension_used"
    private var verifiedConversation = false
    private var conversationDidDegrade = false
    private let numberOfImages: Int
    private let video, file: Bool
    public var text = false

    public var conversation: Conversation? = nil {
        didSet {
            verifiedConversation = conversation?.isTrusted == true
        }
    }

    init(attachments: [NSItemProvider]) {
        video = attachments.contains { $0.hasVideo }
        file = attachments.contains { $0.hasFile }
        numberOfImages = attachments.filter { $0.hasImage }.count
    }

    func markConversationDidDegrade() {
        conversationDidDegrade = true
    }

    func eventDump(sent: Bool) -> StorableTrackingEvent {
        return StorableTrackingEvent(
            name: eventName,
            attributes: [
                "verified_conversation": verifiedConversation,
                "number_of_images": numberOfImages,
                "video": video,
                "file": file,
                "text": text,
                "conversation_did_degrade": conversationDidDegrade,
                "sent": sent,
                ]
        )
    }

}


fileprivate extension NSItemProvider {

    var hasImage: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeImage as String)
    }

    var hasFile: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeData as String) && !hasImage && !hasVideo
    }

    var hasURL: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeURL as String)
    }

    var hasVideo: Bool {
        guard let uti = registeredTypeIdentifiers.first as? String else { return false }
        return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
    }
    
}
