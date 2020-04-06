//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit

final class Token<T: NSObjectProtocol>: Hashable {

    let representedObject: HashBox<T>

    let title: String

    // if title render is longer than this length, it is trimmed with "..."
    var maxTitleWidth: CGFloat = 0

    init(title: String,
         representedObject: T) {
        self.title = title
        self.representedObject = HashBox(value: representedObject)

        maxTitleWidth = .greatestFiniteMagnitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(representedObject)
    }

    static func == (lhs: Token<T>, rhs: Token<T>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
