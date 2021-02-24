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

class ButtonWithLargerHitArea: UIButton {

    // MARK: - Properties

    var hitAreaPadding = CGSize.zero

    // MARK: - Init / Deinit

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setUp()
    }

    private func setUp() {
        isAccessibilityElement = true
    }

     // MARK: - Overridden methods

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if isHidden || alpha == 0 || !isUserInteractionEnabled || !isEnabled {
            return false
        }

        return bounds.insetBy(dx: -hitAreaPadding.width, dy: -hitAreaPadding.height).contains(point)
    }

}

