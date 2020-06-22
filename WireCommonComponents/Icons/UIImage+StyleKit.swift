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

extension StyleKitIcon {

    /**
     * Creates an image of the icon, with specified size and color.
     * - parameter size: The desired size of the image.
     * - parameter color: The color of the image.
     * - returns: The image that represents the icon.
     */

    public func makeImage(size: StyleKitIcon.Size, color: UIColor) -> UIImage {
        let imageProperties = self.renderingProperties
        let imageSize = size.rawValue
        let targetSize = CGSize(width: imageSize, height: imageSize)

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { context in
            context.cgContext.scaleBy(x: imageSize / imageProperties.originalSize, y: imageSize / imageProperties.originalSize)
            imageProperties.renderingMethod(color)
        }
    }

}

extension UIImage {

    /**
     * Creates an image with the specified icon, size and color.
     * - parameter icon: The icon to display.
     * - parameter size: The desired size of the image.
     * - parameter color: The color of the image.
     * - returns: The image to use in the specified configuration.
     */

    public static func imageForIcon(_ icon: StyleKitIcon,
                                    size: CGFloat,
                                    color: UIColor) -> UIImage {
        return icon.makeImage(size: .custom(size), color: color)
    }

    /**
     * Resizes the image to the desired size.
     * - parameter targetSize: The size you want to give to the image.
     * - returns: The resized image.
     * - warning: Passing a target size bigger than the size of the receiver is a
     * programmer error and will cause an assertion failure.
     */

    public func downscaling(to targetSize: CGSize) -> UIImage {
        assert(targetSize.width < size.width)
        assert(targetSize.height < size.height)

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { context in
            context.cgContext.scaleBy(x: targetSize.width / size.width, y: targetSize.height / size.height)
            self.draw(at: .zero)
        }
    }

}

extension UIImageView {

    /**
     * Sets the image of the image view to the given icon, size and color.
     * - parameter icon: The icon to display.
     * - parameter size: The desired size of the image.
     * - parameter color: The color of the image.
     * - returns: The image that represents the icon.
     */

    public func setIcon(_ icon: StyleKitIcon, size: StyleKitIcon.Size, color: UIColor) {
        image = icon.makeImage(size: size, color: color)
    }

    /**
     * Sets the image of the image view to the given icon, size and color and forces its
     * to be always be a template.
     * - parameter icon: The icon to display.
     * - parameter size: The desired size of the image.
     * - parameter color: The color of the image.
     * - returns: The image that represents the icon.
     */

    public func setTemplateIcon(_ icon: StyleKitIcon, size: StyleKitIcon.Size) {
        image = icon.makeImage(size: size, color: .black).withRenderingMode(.alwaysTemplate)
    }

}
