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

struct HorizontalMargins {
    var left: CGFloat
    var right: CGFloat

    init(userInterfaceSizeClass: UIUserInterfaceSizeClass) {
        switch userInterfaceSizeClass {
        case .regular:
            left = 96
            right = 96
        default:
            left = 56
            right = 16
        }
    }
}

extension UITraitEnvironment {
    var conversationHorizontalMargins: HorizontalMargins {
        return conversationHorizontalMargins()
    }

    func conversationHorizontalMargins(windowWidth: CGFloat? = UIApplication.shared.keyWindow?.frame.width) -> HorizontalMargins {
        guard traitCollection.horizontalSizeClass == .regular else {
            return HorizontalMargins(userInterfaceSizeClass: .compact)
        }

        let userInterfaceSizeClass: UIUserInterfaceSizeClass

        /// on iPad 9.7 inch 2/3 mode, right view's width is  396pt, use the compact mode's narrower margin
        if let windowWidth = windowWidth,
            windowWidth <= CGFloat.SplitView.IPadMarginLimit {
            userInterfaceSizeClass = .compact
        } else {
            userInterfaceSizeClass = .regular
        }

        return HorizontalMargins(userInterfaceSizeClass: userInterfaceSizeClass)
    }
}

extension UIView {

    @available(*, deprecated, message: "Use UITraitEnvironment.conversationHorizontalMargins instead")
    class var conversationLayoutMargins: UIEdgeInsets {

        // keyWindow can be nil, in case when running tests or the view is not added to view hierachy
        let horizontalMargins = UIApplication.shared.keyWindow?.conversationHorizontalMargins ?? HorizontalMargins(userInterfaceSizeClass: .compact)

        return UIEdgeInsets(top: 0, left: horizontalMargins.left, bottom: 0, right: horizontalMargins.right)
    }
    
    class var directionAwareConversationLayoutMargins: UIEdgeInsets {
        let margins = conversationLayoutMargins
        
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return UIEdgeInsets(top: margins.top, left: margins.right, bottom: margins.bottom, right: margins.left)
        } else {
            return margins
        }
    }
    
}
