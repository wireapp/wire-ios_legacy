
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

extension UIImage {
    @objc(imageScaledWithFactor:)
    func imageScaled(with scaleFactor: CGFloat) -> UIImage? {
        let size = self.size.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        let scale: CGFloat = 0 // Automatically use scale factor of main screens
        let hasAlpha = false

        UIGraphicsBeginImageContextWithOptions(size, _: !hasAlpha, _: scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }
}
