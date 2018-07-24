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

import UIKit

/**
 * An operation that decodes a UIImage in the background, from its raw data.
 *
 * You can get the decoded image by accessing the `imageData` property once the
 * operation has completed.
 */

class DecodeImageOperation: Operation {

    /// The initial data of the image.
    let imageData: Data

    /// The image that was decoded from the initial data.
    private(set) var decodedImage: UIImage?

    /// Creates the operation from the raw image data.
    init(imageData: Data) {
        self.imageData = imageData
    }

    // MARK: - Decoding

    override func main() {

        guard !isCancelled else {
            return
        }

        guard let rawImage = UIImage(data: imageData)?.cgImage else {
            return
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(data: nil, width: rawImage.width, height: rawImage.height, bitsPerComponent: 8, bytesPerRow: rawImage.width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return
        }

        let imageBounds = CGRect(x: 0, y: 0, width: rawImage.width, height: rawImage.height)
        context.draw(rawImage, in: imageBounds)

        guard let rawDecodedImage = context.makeImage() else {
            return
        }

        decodedImage = UIImage(cgImage: rawDecodedImage)

    }

}
