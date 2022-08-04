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

import Foundation
import UIKit

class StylableButton: UIButton, Stylable {

    var nonLegacyStyle: NonLegacyButtonStyle?

    public func applyStyle(_ style: NonLegacyButtonStyle) {
        self.nonLegacyStyle = style

        setTitleColor(style.normalStateColors.title, for: .normal)
        setTitleColor(style.highlightedStateColors.title, for: .highlighted)

        applyStyleToNonDynamicProperties(style: style)
    }

    private func applyStyleToNonDynamicProperties(style: NonLegacyButtonStyle) {
        setBackgroundImageColor(style.normalStateColors.background, for: .normal)
        setBackgroundImageColor(style.highlightedStateColors.background, for: .highlighted)

        self.layer.borderWidth = 1
        self.layer.borderColor = isHighlighted ? style.normalStateColors.border.cgColor : style.highlightedStateColors.border.cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard let style = nonLegacyStyle else { return }
        applyStyleToNonDynamicProperties(style: style)
    }

    func setBackgroundImageColor(_ color: UIColor?, for state: UIControl.State) {
        if let color = color {
            setBackgroundImage(UIImage.singlePixelImage(with: color), for: state)
        } else {
            setBackgroundImage(nil, for: state)
        }
    }

}
