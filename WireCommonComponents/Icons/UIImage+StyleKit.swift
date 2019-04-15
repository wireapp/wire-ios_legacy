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

import UIKit

extension UIImage {

    /**
     * Creates an image with the specified icon, size and color.
     * - parameter icon: The icon to display.
     * - parameter size: The desired size of the image.
     * - parameter color: The color of the image.
     * - returns: The image to use in the specified configuration.
     */

    @objc public static func imageForIcon(_ icon: StyleKitIcon, size: CGFloat, color: UIColor) -> UIImage {
        return UIImage(icon: icon, size: .custom(size), color: color)
    }

    /**
     * Creates an image with the specified icon, size and color.
     * - parameter icon: The icon to display.
     * - parameter size: The desired size of the image.
     * - parameter color: The color of the image.
     */

    public convenience init(icon: StyleKitIcon, size: StyleKitIconSize, color: UIColor) {
        let imageProperties = icon.renderingProperties
        let imageSize = size.rawValue
        let targetSize = CGSize(width: imageSize, height: imageSize)
        let imageFormat = UIGraphicsImageRendererFormat()
        imageFormat.scale = UIScreen.main.scale

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: imageFormat)

        let image = renderer.image { context in
            context.cgContext.scaleBy(x: imageSize / imageProperties.originalSize, y: imageSize / imageProperties.originalSize)
            imageProperties.renderingMethod(color)
        }

        self.init(cgImage: image.cgImage!)
    }

}
