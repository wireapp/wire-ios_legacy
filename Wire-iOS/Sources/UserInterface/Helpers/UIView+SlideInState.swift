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

import Foundation
import UIKit

enum SlideDirection: UInt {
    case up
    case down
}

extension UIView {
    func wr_animateSlideTo(_ direction: SlideDirection = .down, newState: ()->()) {
        guard let superview = self.superview, let screenshot = snapshotView(afterScreenUpdates: false) else {
            return newState()
        }

        let offset = direction == .down ? -self.frame.size.height : self.frame.size.height
        screenshot.frame = self.frame
        superview.addSubview(screenshot)

        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + offset, width: self.frame.size.width, height: self.frame.size.height)

        newState()

        UIView.animate(easing: .easeInOutExpo, duration: 0.20, animations: {
            self.frame = screenshot.frame
            screenshot.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y - offset, width: self.frame.size.width, height: self.frame.size.height)
            }) { _ in

                screenshot.removeFromSuperview()
        }
    }
}
