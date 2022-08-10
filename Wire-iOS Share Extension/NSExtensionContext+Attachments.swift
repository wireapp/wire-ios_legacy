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

import Foundation
import MobileCoreServices

extension NSExtensionContext {

    /// Get all the attachments to this post.
    var attachments: [NSItemProvider] {
        guard let items = inputItems as? [NSExtensionItem] else { return [] }
        return items.flatMap { $0.attachments ?? [] }
    }

}

// MARK: - Sorting

extension Array where Element == NSItemProvider {

    /// Returns the attachments sorted by type.
    var sorted: [AttachmentType: [NSItemProvider]] {
        var attachments: [AttachmentType: [NSItemProvider]] = [:]

        for attachment in self {
            if attachment.hasImage {
                attachments[.image, default: []].append(attachment)
            } else if attachment.hasVideo {
                attachments[.video, default: []].append(attachment)
            } else if attachment.hasWalletPass {
                attachments[.walletPass, default: []].append(attachment)
            } else if attachment.hasRawFile {
                attachments[.rawFile, default: []].append(attachment)
            } else if attachment.hasURL {
                attachments[.url, default: []].append(attachment)
            } else if attachment.hasFileURL {
                attachments[.fileUrl, default: []].append(attachment)
            }
        }

        return attachments
    }

}

// MARK: - Preview Support

extension Dictionary where Key == AttachmentType, Value == [NSItemProvider] {

    /**
     * Determines the main preview item for the post.
     *
     * We determine this using the following rules:
     * - media = video AND/OR photo
     * - passes OR media OR file
     * - passes OR media OR file > URL
     * - video > photo
     */

    var main: (AttachmentType, NSItemProvider)? {
        let sortedAttachments = self

        for attachmentType in AttachmentType.allCases {
            if let item = sortedAttachments[attachmentType]?.first {
                return (attachmentType, item)
            }
        }

        return nil
    }

}
