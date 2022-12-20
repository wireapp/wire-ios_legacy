//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import WireDataModel
import WireCommonComponents

final class AvailabilityStringBuilder: NSObject {

    static func string(for user: UserType, with style: AvailabilityLabelStyle, color: UIColor? = nil) -> NSAttributedString? {

        var title: String = ""
        var color = color
        let availability = user.availability
        var fontSize: FontSize = .small

        switch style {
        case .list:
            do {
                if let name = user.name {
                    title = name
                }

                fontSize = .normal

                if color == nil {
                    color = SemanticColors.Label.textDefault
                }
            }
        case .participants:
            do {
                title = (user.name ?? "").localizedUppercase
                color = SemanticColors.Label.textDefault
            }
        case .placeholder:
            do {
                guard availability != .none else {
                    // Should use the default placeholder string
                    return nil
                }

                title = "availability.\(availability.canonicalName)".localized.localizedUppercase
            }
        }

        guard let textColor = color else { return nil }
        let icon = AvailabilityStringBuilder.icon(for: availability, with: self.color(for: availability), and: fontSize)
        let attributedText = IconStringsBuilder.iconString(with: icon, title: title, interactive: false, color: textColor)
        return attributedText
    }

    static func icon(for availability: AvailabilityKind, with color: UIColor, and size: FontSize) -> NSTextAttachment? {
        guard availability != .none, let iconType = availability.iconType
            else { return nil }

        let verticalCorrection: CGFloat

        switch size {
        case .small:
            verticalCorrection = -1
        case .medium, .large, .normal, .header, .titleThree, .subHeadline, .bodyTwo, .buttonSmall:
            verticalCorrection = 0
        }

        return NSTextAttachment.textAttachment(for: iconType, with: color, iconSize: 12, verticalCorrection: verticalCorrection)
    }

    static func color(for availability: AvailabilityKind) -> UIColor {
        typealias IconColors = SemanticColors.Icon
        switch availability {
        case .none:
            return UIColor.clear
        case .available:
            return IconColors.foregroundAvailabilityAvailable
        case .busy:
            return IconColors.foregroundAvailabilityBusy
        case .away:
            return IconColors.foregroundAvailabilityAway
        }
    }
}
