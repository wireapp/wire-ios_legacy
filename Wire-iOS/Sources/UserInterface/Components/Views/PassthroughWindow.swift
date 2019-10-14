//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
class PassthroughWindow: UIWindow {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for v in subviews {
            if !v.isHidden && v.point(inside: convert(point, to: v), with: event) {
                return true
            }
        }

        return false
    }

    override var isOpaque: Bool {
        get {
            return false
        }

        set {
            // no op
        }
    }
}
