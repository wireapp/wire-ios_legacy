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
    private(set) var disabledOnStateColor: UIColor
    private(set) var disabledOffStateColor: UIColor
    
    // Predefined styles:
    static let basic: Self = SwitchStyle(
        onStateColor: SemanticColors.backgroundSwitchOnEnabled,
        offStateColor: SemanticColors.backgroundSwitchOffEnabled,
        disabledOnStateColor: SemanticColors.backgroundSwitchOnDisabled,
        disabledOffStateColor: SemanticColors.backgroundSwitchOffDisabled)
    
    static let verified: Self = SwitchStyle(
        onStateColor: SemanticColors.backgroundSwitchOnVerified,
        offStateColor: SemanticColors.backgroundSwitchOffEnabled,
        disabledOnStateColor: SemanticColors.backgroundSwitchOnDisabled,
        disabledOffStateColor: SemanticColors.backgroundSwitchOffDisabled)
}

extension UISwitch: Stylable {
    func applyStyle(_ style: SwitchStyle) {
        if isEnabled {
            /*For on state (enabled)*/
            self.onTintColor = style.onStateColor

            /*For off state (disabled)*/
            self.layer.cornerRadius = self.frame.height / 2.0
            self.backgroundColor = style.offStateColor
            self.clipsToBounds = true
        } else {
            /*For on state (enabled)*/
            self.onTintColor = style.disabledOnStateColor

            /*For off state (disabled)*/
            self.layer.cornerRadius = self.frame.height / 2.0
            self.backgroundColor = style.disabledOffStateColor
            self.clipsToBounds = true
        }
    }

}
