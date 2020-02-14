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

extension UIView {///TODO: delay?
    @objc(wr_animateWithEasing:duration:animations:completion:)
    class func wr_animate(easing: EasingFunction,
                          duration: TimeInterval,
                          animations: @escaping () -> Void,
                          completion: @escaping ResultHandler) {
        animate(easing: easing, duration: duration, animations: animations, completion: completion)
    }

    class func animate(easing: EasingFunction,
                       duration: TimeInterval,
                       animations: @escaping () -> Void, completion: ResultHandler? = nil) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(easing.timingFunction)
        
        UIView.animate(withDuration: duration, animations: animations, completion: completion)
        
        CATransaction.commit()
    }
}


