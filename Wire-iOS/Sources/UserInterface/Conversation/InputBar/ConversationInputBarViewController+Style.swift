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

extension ConversationInputBarViewController {
    @objc func setupStyle() {
        ephemeralIndicatorButton.borderWidth = 0.0
        ephemeralIndicatorButton.titleLabel?.font = UIFont.smallSemiboldFont
        hourglassButton.setIconColor(.iconNormal, for: .normal)
        hourglassButton.setIconColor(.iconHighlighted, for: .highlighted)
        hourglassButton.setIconColor(.iconNormal, for: .selected)

        hourglassButton.setBackgroundImageColor(.clear, for: .selected)
    }
}
