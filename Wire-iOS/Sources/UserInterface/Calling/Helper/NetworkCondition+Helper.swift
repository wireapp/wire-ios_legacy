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

import WireSyncEngine

extension NetworkQuality {
    func attributedString(color: UIColor) -> NSAttributedString? {
        if isNormal {
            return nil
        } else {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(for: .networkCondition, iconSize: .tiny, color: color)
            attachment.bounds = CGRect(x: 0.0, y: -4, width: attachment.image!.size.width, height: attachment.image!.size.height)
            let text = "conversation.status.poor_connection".localized.uppercased()
            let attributedText = text.attributedString.adding(font: FontSpec(.small, .semibold).font!, to: text).adding(color: color, to: text)
            return NSAttributedString(attachment: attachment) + " " + attributedText
        }
    }

    var isNormal: Bool {
        switch self {
        case .normal:
            return true
        case .medium, .poor:
            return false
        }
    }
}
