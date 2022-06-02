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
import WireLinkPreview
import WireDataModel
import WireUtilities

@objcMembers public final class LinkPreviewPreprocessor: LinkPreprocessor<LinkMetadata> {

    fileprivate let linkPreviewDetector: LinkPreviewDetectorType

    public init(linkPreviewDetector: LinkPreviewDetectorType, managedObjectContext: NSManagedObjectContext) {
        self.linkPreviewDetector = linkPreviewDetector
        let log = ZMSLog(tag: "link previews")
        super.init(managedObjectContext: managedObjectContext, zmLog: log)
    }

    public override func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let predicate = NSPredicate(format: "%K == %d", ZMClientMessage.linkPreviewStateKey, ZMLinkPreviewState.waitingToBeProcessed.rawValue)
        return ZMClientMessage.sortedFetchRequest(with: predicate)
    }

    override func objectsToPreprocess(_ object: NSObject) -> ZMClientMessage? {
        guard let message = object as? ZMClientMessage else { return nil }
        return message.linkPreviewState == .waitingToBeProcessed ? message : nil
    }

    override func processLinks(in message: ZMClientMessage, text: String, excluding excludedRanges: [NSRange]) {
        linkPreviewDetector.downloadLinkPreviews(inText: text, excluding: excludedRanges) { [weak self] linkPreviews in
            self?.managedObjectContext.performGroupedBlock {
                self?.zmLog.debug("\(linkPreviews.count) previews for: \(message.nonce?.uuidString ?? "nil")\n\(linkPreviews)")
                self?.didProcessMessage(message, result: linkPreviews)
            }
        }
    }

    override func didProcessMessage(_ message: ZMClientMessage, result linkPreviews: [LinkMetadata]) {
        finishProcessing(message)

        if let preview = linkPreviews.first, let messageText = message.textMessageData?.messageText, let mentions = message.textMessageData?.mentions, !message.isObfuscated {

            let updatedText = Text(content: messageText, mentions: mentions, linkPreviews: [preview], replyingTo: nil)
            let updatedMessage = GenericMessage(content: updatedText, nonce: message.nonce!, expiresAfterTimeInterval: message.deletionTimeout)

            do {
                try message.setUnderlyingMessage(updatedMessage)
            } catch {
                zmLog.warn("Failed to set link preview on client message. Reason: \(error.localizedDescription) Resetting state to try again later.")
                message.linkPreviewState = .waitingToBeProcessed
                return
            }

            if let imageData = preview.imageData.first {
                zmLog.debug("image in linkPreview (need to upload), setting state to .downloaded for: \(message.nonce?.uuidString ?? "nil")")
                managedObjectContext.zm_fileAssetCache.storeAssetData(message, format: .original, encrypted: false, data: imageData)
                message.linkPreviewState = .downloaded
            } else {
                zmLog.debug("no image in preview, setting state to .uploaded for: \(message.nonce?.uuidString ?? "nil")")
                message.linkPreviewState = .uploaded
            }
        } else {
            zmLog.debug("no linkpreview or obfuscated message, setting state to .done for: \(message.nonce?.uuidString ?? "nil")")
            message.linkPreviewState = .done
        }

        // The change processor is called as a response to a context save,
        // which is why we need to enque a save maually here
        managedObjectContext.enqueueDelayedSave()
    }

}
