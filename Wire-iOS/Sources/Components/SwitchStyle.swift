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
    static let `default`: Self = SwitchStyle(
        enabledOnStateColor: SemanticColors.SwitchColors.backgroundSwitchOnStateEnabled,
        enabledOffStateColor: SemanticColors.SwitchColors.backgroundSwitchOffStateEnabled
    )
}

extension UISwitch: Stylable {
    convenience init(style switchStyle: SwitchStyle = .default) {
        self.init()
        applyStyle(switchStyle)
    }
    public func applyStyle(_ style: SwitchStyle) {
        self.onTintColor = style.enabledOnStateColor
        self.layer.cornerRadius = self.frame.height / 2.0
        self.backgroundColor = style.enabledOffStateColor
        self.clipsToBounds = true
    }
}
