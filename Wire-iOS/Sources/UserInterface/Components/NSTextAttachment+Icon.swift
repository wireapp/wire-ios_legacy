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

extension NSTextAttachment {
    static func textAttachment(for icon: ZetaIconType, with color: UIColor, iconSize: CGFloat = 10, verticalCorrection: CGFloat = 0) -> NSTextAttachment? {
        guard let image = UIImage(for: icon, fontSize: iconSize, color: color)
            else { return nil }

        let attachment = NSTextAttachment()
        attachment.image = image
        let ratio = image.size.width / image.size.height
        attachment.bounds = CGRect(x: 0, y: verticalCorrection, width: iconSize * ratio, height: iconSize)
        return attachment
    }
}
