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

public struct SwitchStyle {
    private(set) var enabledOnStateColor: UIColor
    private(set) var enabledOffStateColor: UIColor
    private(set) var disabledOnStateColor: UIColor
    private(set) var disabledOffStateColor: UIColor
    static let `default`: Self = SwitchStyle(
        enabledOnStateColor:
            SemanticColors.SwitchColors.backgroundSwitchOnStateEnabled,
        enabledOffStateColor: SemanticColors.SwitchColors.backgroundSwitchOffStateEnabled,
        disabledOnStateColor: SemanticColors.SwitchColors.backgroundSwitchOnStateDisabled,
        disabledOffStateColor: SemanticColors.SwitchColors.backgroundSwitchOffStateDisabled)
}

extension UISwitch: Stylable {
    convenience init(_ style: SwitchStyle = .default) {
        self.init()
        applyStyle(style)
    }
    public func applyStyle(_ style: SwitchStyle) {
        self.onTintColor = isEnabled ? style.enabledOnStateColor : style.disabledOnStateColor
        self.layer.cornerRadius = self.frame.height / 2.0
        self.backgroundColor =  isEnabled ? style.enabledOffStateColor : style.disabledOffStateColor
        self.clipsToBounds = true
    }
}
