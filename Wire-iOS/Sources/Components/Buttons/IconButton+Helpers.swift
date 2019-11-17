//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireCommonComponents

extension IconButton {

    func icon(for state: UIControl.State) -> StyleKitIcon? {
        return iconDefinition(for: state)?.iconType
    }

    func setIcon(_ icon: StyleKitIcon?, size: StyleKitIcon.Size, for state: UIControl.State, renderingMode: UIImage.RenderingMode = .alwaysTemplate) {
        if let icon = icon {
            self.__setIcon(icon, withSize: size.rawValue, for: state, renderingMode: renderingMode)
        } else {
            self.removeIcon(for: state)
        }
    }

    func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        state.expanded.forEach(){ expandedState in
            if color != nil {
                borderColorByState[NSNumber(value: expandedState.rawValue)] = color
                
                if adjustsBorderColorWhenHighlighted &&
                   expandedState == .normal {
                    borderColorByState[NSNumber(value: UIControl.State.highlighted.rawValue)] = color?.mix(.black, amount: 0.4)
                }
            }
        }
        
        updateBorderColor()
    }
}
