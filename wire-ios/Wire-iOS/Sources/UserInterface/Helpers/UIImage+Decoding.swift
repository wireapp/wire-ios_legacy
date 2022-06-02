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
import UIKit

extension UIImage {

    /// Decode UIImage. This will prevent it from happening later in the rendering path.

    var decoded: UIImage? {
        guard
            let rawImage = cgImage,
            let context = CGContext.fromRawImage(rawImage)
        else {
            return  nil
        }

        let imageBounds = CGRect(x: 0, y: 0, width: rawImage.width, height: rawImage.height)
        context.draw(rawImage, in: imageBounds)

        guard let rawDecodedImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: rawDecodedImage)
    }

}

private extension CGContext {

    static func fromRawImage(_ rawImage: CGImage) -> CGContext? {
        return CGContext(data: nil,
                         width: rawImage.width,
                         height: rawImage.height,
                         bitsPerComponent: 8,
                         bytesPerRow: rawImage.width * 4,
                         space: CGColorSpaceCreateDeviceRGB(),
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

}
