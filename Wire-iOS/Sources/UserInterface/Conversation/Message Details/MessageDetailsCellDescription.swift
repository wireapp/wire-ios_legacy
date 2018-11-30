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

import UIKit

/**
 * The description of a cell for message details.
 * - note: This class needs to be NSCopying to be used in an ordered set for diffing.
 */

class MessageDetailsCellDescription: NSObject, NSCopying {
    /// The user to display.
    let user: ZMUser

    /// The subtitle string to display under the user name.
    let subtitle: String?

    /// The attributed string for the subtitle.
    var attributedTitle: NSAttributedString? {
        return subtitle.map { $0 && UserCell.boldFont }
    }

    // MARK: - Initialization

    /// Creates a new cell description.
    init(user: ZMUser, subtitle: String?) {
        self.user = user
        self.subtitle = subtitle
    }

    // MARK: - NSCopying

    override var hash: Int {
        return user.hash
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherDescription = object as? MessageDetailsCellDescription else {
            return false
        }

        return user == otherDescription.user && subtitle == otherDescription.subtitle
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return MessageDetailsCellDescription(user: user, subtitle: subtitle)
    }
}
