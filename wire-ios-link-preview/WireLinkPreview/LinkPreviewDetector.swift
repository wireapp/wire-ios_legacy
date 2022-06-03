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
import WireUtilities

public protocol LinkPreviewDetectorType {

    func downloadLinkPreviews(inText text: String, excluding: [NSRange], completion: @escaping ([LinkMetadata]) -> Void)

}

public final class LinkPreviewDetector: NSObject, LinkPreviewDetectorType {

    private let linkDetector: NSDataDetector? = NSDataDetector.linkDetector
    private let previewDownloader: PreviewDownloaderType
    private let imageDownloader: ImageDownloaderType
    private let workerQueue: OperationQueue

    public typealias DetectCompletion = ([LinkMetadata]) -> Void

    public convenience override init() {
        let workerQueue = OperationQueue()
        self.init(
            previewDownloader: PreviewDownloader(resultsQueue: workerQueue),
            imageDownloader: ImageDownloader(resultsQueue: workerQueue),
            workerQueue: workerQueue
        )
    }

    init(previewDownloader: PreviewDownloaderType, imageDownloader: ImageDownloaderType, workerQueue: OperationQueue) {
        self.workerQueue = workerQueue
        self.previewDownloader = previewDownloader
        self.imageDownloader = imageDownloader
        super.init()
    }

    /**
     Downloads the link preview data, including their images, for links contained in the text.
     The preview data is generated from the [Open Graph](http://ogp.me) information contained in the head of the html of the link.
     For debugging Open Graph please use the [Sharing Debugger](https://developers.facebook.com/tools/debug/sharing).

     The completion block will be called on private background queue, make sure to switch to main or other queue.

     **Attention: For now this method only downloads the preview data (and only one image for this link preview) 
     for the first link found in the text!**

     - parameter text:       The text with potentially contained links, if links are found the preview data is downloaded.
     - parameter exluding:   Ranges in the text which should be skipped when searching for links.
     - parameter completion: The completion closure called when the link previews (and it's images) have been downloaded.
     */
    public func downloadLinkPreviews(inText text: String, excluding: [NSRange] = [], completion : @escaping DetectCompletion) {
        guard let (url, range) = linkDetector?.detectLinksAndRanges(in: text, excluding: excluding).first, !PreviewBlacklist.isBlacklisted(url) else { return completion([]) }
        previewDownloader.requestOpenGraphData(fromURL: url) { [weak self] openGraphData in
            guard let `self` = self, let substringRange = Range<String.Index>(range, in: text) else { return }
            let originalURLString = String(text[substringRange])
            guard let data = openGraphData else { return completion([]) }

            let linkPreview = data.linkPreview(originalURLString, offset: range.location)
            linkPreview.requestAssets(withImageDownloader: self.imageDownloader) { _ in
                completion([linkPreview])
            }
        }
    }

    deinit {
        previewDownloader.tearDown()
    }

}
