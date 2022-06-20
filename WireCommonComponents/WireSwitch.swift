//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

struct SwitchStyle {

    private(set) var onStateColor: UIColor
    private(set) var offStateColor: UIColor
    
    static let enabled: Self = SwitchStyle(
        onStateColor: SemanticColors.backgroundSwitchOnEnabled,
        offStateColor: SemanticColors.backgroundSwitchOffEnabled)
    
    static let disabled: Self = SwitchStyle(
        onStateColor: SemanticColors.backgroundSwitchOnDisabled,
        offStateColor: SemanticColors.backgroundSwitchOffDisabled)
}

extension UISwitch: Stylable {

    func applyStyle(_ style: SwitchStyle) {
        /*For on state*/
        self.onTintColor = style.onStateColor

        /*For off state*/
        self.layer.cornerRadius = self.frame.height / 2.0
        self.backgroundColor = style.offStateColor
        self.clipsToBounds = true
    }

}
