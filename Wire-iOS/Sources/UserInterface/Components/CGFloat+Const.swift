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

extension CGFloat {
    enum StartUI {
        static public let CellHeight: CGFloat = 56
    }
    
    enum SplitView {
        static public let LeftViewWidth: CGFloat = 336

        /// on iPad 9.7 inch 2/3 mode, right view's width is  396pt, use the compact mode's narrower margin
        /// when the window is small then or equal to (396 + LeftViewWidth = 732), use compact mode margin
        static public let IPadMarginLimit: CGFloat = 732
    }

    enum ConversationListHeader {
        /// 75% of ConversationAvatarView.iconWidth
        static let iconWidth: CGFloat = 24
    }

    enum ConversationAvatarView {
        static let iconWidth: CGFloat = 32
    }

    enum AccountView {
        static let iconWidth: CGFloat = 32
    }
}

