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

extension UIImage: MediaAsset {
    public func data() -> Data? {
        if isTransparent() {
            return UIImagePNGRepresentation(self)
        } else {
            return UIImageJPEGRepresentation(self, 1.0)
        }
    }

    public func isGIF() -> Bool {
        return false
    }

    public func isTransparent() -> Bool {
        guard let alpha: CGImageAlphaInfo = self.cgImage?.alphaInfo else { return false }

        switch alpha {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
            return true
        default:
            return false
        }
    }
}

extension UIImage {
    @objc func downsizedImage() -> UIImage {
        let longestLength = self.size.longestLength

        /// Maximum image size that would show in a UIImageView.
        /// (Tested on iPhone 5s, maxImageLength = 3000 may crash due to memory usage)
        let maxImageLength = CGFloat(2500) * UIScreen.main.scale
        guard longestLength > maxImageLength else { return self }

        let ratio = maxImageLength / longestLength
        return imageScaled(withFactor: ratio)
    }
}
