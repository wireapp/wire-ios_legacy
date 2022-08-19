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
import WireCommonComponents

extension NSTextAttachment {
    static func textAttachment(for icon: StyleKitIcon,
                               with color: UIColor,
                               iconSize: StyleKitIcon.Size = 10,
                               verticalCorrection: CGFloat = 0,
                               insets: UIEdgeInsets? = nil,
                               borderWidth: CGFloat? = nil) -> NSTextAttachment {
        var image: UIImage
        if let insets = insets {
            image = icon.makeImage(size: iconSize, color: color).with(insets: insets, backgroundColor: .clear)!
        } else {
            image = icon.makeImage(size: iconSize, color: color)
        }

        if let borderWidth = borderWidth {
            image = image.imageWithBorder(width: borderWidth, color: SemanticColors.View.borderAvailabilityIcon, iconSize: iconSize.rawValue)!
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        let ratio = image.size.width / image.size.height
        attachment.bounds = CGRect(x: 0, y: verticalCorrection, width: iconSize.rawValue * ratio, height: iconSize.rawValue)
        return attachment
    }
}

extension UIImage {
    func imageWithBorder(width: CGFloat, color: UIColor, iconSize: CGFloat) -> UIImage? {
        let square = CGSize(width: min(size.width, size.height) + width, height: min(size.width, size.height) + width)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = .center
        imageView.image = self
        imageView.layer.borderWidth = width
        imageView.layer.borderColor = color.cgColor
        imageView.layer.cornerRadius = iconSize / 2
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
