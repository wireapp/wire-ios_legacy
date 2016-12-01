//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


fileprivate let smallLightFont = UIFont(magicIdentifier: "style.text.small.font_spec_light")!
fileprivate let smallBoldFont = UIFont(magicIdentifier: "style.text.small.font_spec_bold")!
fileprivate let normalBoldFont = UIFont(magicIdentifier: "style.text.normal.font_spec_bold")!

fileprivate let dimmedColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextDimmed)
fileprivate let textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground)


@objc public class AddressBookCorrelationFormatter: NSObject {

    let lightFont, boldFont: UIFont
    let color: UIColor

    init(lightFont: UIFont, boldFont: UIFont, color: UIColor) {
        self.lightFont = lightFont
        self.boldFont = boldFont
        self.color = color
    }

    private func addressBookText(for user: ZMBareUser & ZMSearchableUser, with addressBookName: String) -> NSAttributedString? {
        guard !user.isSelfUser else { return nil }
        let suffix = "conversation.connection_view.in_address_book".localized && lightFont && color
        if addressBookName.lowercased() == user.name.lowercased() {
            return suffix
        }

        let contactName = addressBookName && boldFont && color
        return contactName + " " + suffix
    }

    func correlationText(for user: ZMBareUser & ZMSearchableUser, with count: Int, addressBookName: String?) -> NSAttributedString? {
        if let name = addressBookName, let addressBook = addressBookText(for: user, with: name) {
            return addressBook
        }

        guard count > 0 && !user.isConnected else { return nil }
        let prefix = String(format: "%ld", count) && boldFont && color
        return prefix + " " + ("conversation.connection_view.common_connections".localized && lightFont && color)
    }

}


@objc final class ProfileHeaderViewModel: NSObject {

    let title: NSAttributedString
    let subtitle: NSAttributedString?
    let correlationText: NSAttributedString?
    let style: ProfileHeaderStyle

    static var formatter: AddressBookCorrelationFormatter = {
        AddressBookCorrelationFormatter(lightFont: smallLightFont, boldFont: smallBoldFont, color: dimmedColor)
    }()

    init(user: ZMUser?, fallbackName fallback: String, addressBookName: String?, commonConnections: Int, style: ProfileHeaderStyle) {
        self.style = style
        title = ProfileHeaderViewModel.attributedTitle(for: user, fallback: fallback)
        subtitle = ProfileHeaderViewModel.attributedSubtitle(for: user)
        correlationText = ProfileHeaderViewModel.attributedCorrelationText(for: user, with: commonConnections, addressBookName: addressBookName)
    }

    static func attributedTitle(for user: ZMUser?, fallback: String) -> NSAttributedString {
        return (user?.name ?? fallback) && normalBoldFont && textColor
    }

    static func attributedSubtitle(for user: ZMUser?) -> NSAttributedString? {
        guard let handle = user?.handle else { return nil }
        return ("@" + handle) && smallBoldFont && dimmedColor
    }

    static func attributedCorrelationText(for user: ZMUser?, with connections: Int, addressBookName: String?) -> NSAttributedString? {
        guard let user = user else { return nil }
        return formatter.correlationText(for: user, with: connections, addressBookName: addressBookName)
    }

}
