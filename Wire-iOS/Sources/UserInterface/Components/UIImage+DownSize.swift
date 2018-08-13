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


extension CGFloat {
    enum Image {
        static public let maxSupportedLength: CGFloat = 5000
    }
}

extension UIImage {
    @objc func downsizedImage() -> UIImage {
        let longestLength = self.size.longestLength

        /// Maximum image size that would show in a UIImageView.
        /// Tested on iPhone 5s and found that the image size limitation is ~5000px
        let maxImageLength = CGFloat.Image.maxSupportedLength
        guard longestLength > maxImageLength else { return self }

        let ratio = (maxImageLength / UIScreen.main.scale) / longestLength
        return imageScaled(withFactor: ratio)
    }
}
