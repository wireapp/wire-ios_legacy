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
        return name && UIFont(magicIdentifier: "style.text.normal.font_spec_bold")
    }

    static func attributedSubtitle(for user: ZMUser?) -> NSAttributedString? {
        guard let user = user else { return nil }

        if let handle = user.handle {
            return handle && UIFont(magicIdentifier: "style.text.small.font_spec_light")
        }

        guard let mail = user.emailAddress, mail.characters.count > 0 else { return nil }
        if (user.isConnected || user.isPendingApprovalBySelfUser || user.isSelfUser || user.isBlocked) {
            return user.emailAddress && UIFont(magicIdentifier: "style.text.small.font_spec_light") && UIColor.accent()
        }

        return nil
    }

    static func attributedCorelationText(for user: ZMUser?) -> NSAttributedString? {
        guard let user = user else { return nil }
        let contact: ZMAddressBookContact? = user.contact()
        guard let correlation = contact?.name else { return nil }
        guard correlation.caseInsensitiveCompare(user.name) != .orderedSame else { return nil }
        return correlation && UIFont(magicIdentifier: "style.text.small.font_spec_light") && UIColor.wr_color(fromColorScheme: ColorSchemeColorTextDimmed)
    }

}
