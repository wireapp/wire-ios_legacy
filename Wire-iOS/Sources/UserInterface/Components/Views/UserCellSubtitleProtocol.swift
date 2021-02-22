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
import WireDataModel

protocol UserCellSubtitleProtocol: class {
    func subtitle(forRegularUser user: UserType?) -> NSAttributedString?

    static var correlationFormatters: [ColorSchemeVariant: AddressBookCorrelationFormatter] { get set }

    static var boldFont: UIFont { get }
    static var lightFont: UIFont { get }
}

extension UserCellSubtitleProtocol where Self: UIView & Themeable {
    func subtitle(forRegularUser user: UserType?) -> NSAttributedString? {
        guard let user = user else { return nil }

        var components: [NSAttributedString?] = []

        if let handle = user.handle, !handle.isEmpty {
            components.append("@\(handle)" && UserCell.boldFont)
        }

        WirelessExpirationTimeFormatter.shared.string(for: user).apply {
            components.append($0 && UserCell.boldFont)
        }

        if let user = user as? ZMUser, let addressBookName = user.addressBookEntry?.cachedName {
            let formatter = Self.correlationFormatter(for: colorSchemeVariant)
            components.append(formatter.correlationText(for: user, addressBookName: addressBookName))
        }

        return components.compactMap({ $0 }).joined(separator: " " + String.MessageToolbox.middleDot + " " && UserCell.lightFont)
    }

    private static func correlationFormatter(for colorSchemeVariant: ColorSchemeVariant) -> AddressBookCorrelationFormatter {
        if let formatter = correlationFormatters[colorSchemeVariant] {
            return formatter
        }

        let color = UIColor.from(scheme: .sectionText, variant: colorSchemeVariant)
        let formatter = AddressBookCorrelationFormatter(lightFont: lightFont, boldFont: boldFont, color: color)

        correlationFormatters[colorSchemeVariant] = formatter

        return formatter
    }

}
