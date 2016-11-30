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


class AddressBookCorrelationFormatter {

    private static func addressBookText(for user: ZMUser, with addressBookName: String) -> NSAttributedString? {
        guard !user.isSelfUser else { return nil }
        let suffix = "conversation.connection_view.in_address_book".localized && smallLightFont && dimmedColor
        if addressBookName.lowercased() == user.name {
            return suffix
        }

        let contactName = addressBookName && smallBoldFont && dimmedColor
        return contactName + " " + suffix
    }

    static func correlationText(for user: ZMUser, with count: UInt, addressBookName: String) -> NSAttributedString {
        if let addressBook = addressBookText(for: user, with: addressBookName) {
            return addressBook
        }

        let prefix = String(format: "%ld", count) && smallBoldFont && dimmedColor
        return prefix + " " + ("conversation.connection_view.common_connections".localized && smallLightFont && dimmedColor)
    }

}


@objc final class ProfileHeaderViewModel: NSObject {

    let title: NSAttributedString
    let subtitle: NSAttributedString?
    let correlationText: NSAttributedString?
    let style: ProfileHeaderStyle

    init(user: ZMUser?, fallbackName fallback: String, style: ProfileHeaderStyle) {
        self.style = style
        title = ProfileHeaderViewModel.attributedTitle(for: user, fallback: fallback)
        subtitle = ProfileHeaderViewModel.attributedSubtitle(for: user)
        correlationText = ProfileHeaderViewModel.attributedCorelationText(for: user)
    }

    static func attributedTitle(for user: ZMUser?, fallback: String) -> NSAttributedString {
        let name = user?.name ?? fallback
        return name.uppercased() && normalBoldFont && textColor
    }

    static func attributedSubtitle(for user: ZMUser?) -> NSAttributedString? {
        guard let user = user else { return nil }

        if let handle = user.handle {
            return ("@" + handle) && smallBoldFont && dimmedColor
        }

        guard let mail = user.emailAddress, mail.characters.count > 0 else { return nil }
        if (user.isConnected || user.isPendingApprovalBySelfUser || user.isSelfUser || user.isBlocked) {
            return user.emailAddress && smallLightFont && UIColor.accent()
        }

        return nil
    }

    static func attributedCorelationText(for user: ZMUser?) -> NSAttributedString? {
        guard let user = user else { return nil }
        // TODO: User actual common connections count
        return AddressBookCorrelationFormatter.correlationText(for: user, with: 5, addressBookName: "Egon")
    }

}
