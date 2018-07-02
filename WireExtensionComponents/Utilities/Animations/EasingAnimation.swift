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
 * An animation that interpolates the values between a start and finish value,
 * along the selected curve, for the property at the given key path.
 *
 * The default curve is `linear`. The values of the key frames will be recomputed
 * every time the easing function, from value, to value or duration are changed.
 *
 * - warning: Do not set the `values` or `path` properties manually.
 */

@objc(WREasingAnimation)
public class EasingAnimation: CAKeyframeAnimation {

    /// The function to use to animate the progress.
    @objc public var easing: EasingFunction = .linear {
        didSet {
            timingFunction = easing.timingFunction
        }
    }

    /// The initial value for animated the key path.
    @objc public var fromValue: Any? = nil {
        didSet {
            updateValues()
        }
    }

    /// The final value to assign to the key path when the animation finishes.
    @objc public var toValue: Any? = nil  {
        didSet {
            updateValues()
        }
    }

    // MARK: - Animation Values

    private func updateValues() {

        guard let fromValue = self.fromValue, let toValue = self.toValue else {
            values = []
            return
        }

        values = [fromValue, toValue]
        
    }

}
