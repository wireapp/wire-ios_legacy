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

import UIKit

/// A derative of UIView whose main body is completely invisible to touches so they are passed through to whatever is below, yet its subviews and subsubviews in designated classes still process the touches.
final class PassthroughTouchesView: UIView {
    override var isOpaque: Bool {
        get {
            return false
        }

        set {
            // no-op
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard bounds.contains(point) else {
            return false
        }

        for subview in subviews {

            // Don’t consider hidden subviews in hit testing
            if subview.isHidden || subview.alpha == 0 {
                continue
            }

            let translatedPoint = convert(point, to: subview)
            if subview.point(inside: translatedPoint, with: event) {
                return true
            }

            // 1st level subviews did not match, so iterate through 2nd level

            for subSubview in subview.subviews {
                let translatedSubSubPoint = convert(point, to: subSubview)
                if subview.point(inside: translatedPoint, with: event) && subSubview.point(inside: translatedSubSubPoint, with: event) {
                    return true
                }
            }
        }

        return false
    }
}
