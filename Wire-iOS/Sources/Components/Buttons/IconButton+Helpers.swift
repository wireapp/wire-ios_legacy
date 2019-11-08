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

    convenience init(style: IconButtonStyle, variant: ColorSchemeVariant) {
        self.init()
        
        setIconColor(UIColor.from(scheme: .iconNormal, variant: variant), for: .normal)
        setIconColor(UIColor.from(scheme: .iconSelected, variant: variant), for: .selected)
        setIconColor(UIColor.from(scheme: .iconHighlighted, variant: variant), for: .highlighted)
        setBackgroundImageColor(UIColor.from(scheme: .iconBackgroundSelected, variant: variant), for: .selected)
        
        switch style {
        case .default:
            break
        case .circular:
            circular = true
            borderWidth = 0
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            contentHorizontalAlignment = .center
        case .navigation:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
            titleLabel?.font = UIFont.smallLightFont
            adjustsImageWhenDisabled = false
            borderWidth = 0
            contentHorizontalAlignment = .left
        default:
            break
        }
    }
}
