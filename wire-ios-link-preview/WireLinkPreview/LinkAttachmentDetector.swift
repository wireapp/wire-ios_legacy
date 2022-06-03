//
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

/**
 * An object that can detect link attachments in a text message.
 *
 * Link attachments differ from link previews in the fact that they're not added to
 * the payload of the message. We need to parse them when sending and receiving a
 * message.
 */

public protocol LinkAttachmentDetectorType {

    /**
     * Downloads the link attachment, including their images, for links contained in the text.
     * The preview data is generated from the [Open Graph](http://ogp.me) information contained in the head of the html of the link.
     * For debugging Open Graph please use the [Sharing Debugger](https://developers.facebook.com/tools/debug/sharing).
     *
     * The completion block will be called on private background queue, make sure to switch to main or other queue.
     *
     * **Attention: For now this method only downloads the preview data (and only one image for this link preview)
     * for the first attachment-eligible link found in the text!**
     *
     * - parameter text:       The text with potentially contained links, if links are found the preview data is downloaded.
     * - parameter excludedRanges:   Ranges in the text which should be skipped when searching for links.
     * - parameter completion: The completion closure called when the link attachments (and it's images) have been downloaded.
     * - parameter detectedAttachments: The attachments that were detected in the text message.
     */

    func downloadLinkAttachments(inText text: String, excluding excludedRanges: [NSRange], completion: @escaping (_ detectedAttachments: [LinkAttachment]) -> Void)

}

/**
 * A concrete implementation of the `LinkAttachmentDetectorType` protocol to detect link attachments using OpenGraph.
 */

public final class LinkAttachmentDetector: NSObject, LinkAttachmentDetectorType {

    private let linkDetector: NSDataDetector? = NSDataDetector.linkDetector
    private let previewDownloader: PreviewDownloaderType
    private let workerQueue: OperationQueue

    deinit {
        previewDownloader.tearDown()
    }

    public convenience override init() {
        let workerQueue = OperationQueue()
        self.init(
            previewDownloader: PreviewDownloader(resultsQueue: workerQueue),
            workerQueue: workerQueue
        )
    }

    init(previewDownloader: PreviewDownloaderType, workerQueue: OperationQueue) {
        self.workerQueue = workerQueue
        self.previewDownloader = previewDownloader
        super.init()
    }

    public func downloadLinkAttachments(inText text: String, excluding excludedRanges: [NSRange] = [], completion : @escaping ([LinkAttachment]) -> Void) {
        guard let (url, (type, range)) = linkDetector?.detectLinkAttachments(in: text, excluding: excludedRanges).first else { return completion([]) }

        previewDownloader.requestOpenGraphData(fromURL: url) { openGraphData in
            guard let data = openGraphData else { return completion([]) }
            guard let linkAttachment = LinkAttachment(openGraphData: data, detectedType: type, originalRange: range) else { return }
            completion([linkAttachment])
        }
    }

}
