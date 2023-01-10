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

    var buttonStyle: ButtonStyle?

    public func applyStyle(_ style: ButtonStyle) {
        self.buttonStyle = style

        setTitleColor(style.normalStateColors.title, for: .normal)
        setTitleColor(style.highlightedStateColors.title, for: .highlighted)
        setTitleColor(style.selectedStateColors?.title, for: .selected)

        applyStyleToNonDynamicProperties(style: style)
    }

    private func applyStyleToNonDynamicProperties(style: ButtonStyle) {
        setBackgroundImageColor(style.normalStateColors.background, for: .normal)
        setBackgroundImageColor(style.highlightedStateColors.background, for: .highlighted)
        setBackgroundImageColor(style.selectedStateColors?.background, for: .selected)

        setBorder(for: style)
    }

    private func setBorder(for style: ButtonStyle) {
        guard style.highlightedStateColors.border != nil ||
                style.normalStateColors.border != nil ||
                style.selectedStateColors?.border != nil else { return }
        let normalStateColor = style.normalStateColors.border?.cgColor ?? UIColor.clear.cgColor
        let highlightedStateColor = style.highlightedStateColors.border?.cgColor ?? UIColor.clear.cgColor
        let selectedStateColor = style.selectedStateColors?.border.cgColor ?? UIColor.clear.cgColor
        self.layer.borderWidth = 1
        self.layer.borderColor = isHighlighted ? highlightedStateColor : normalStateColor
        self.layer.borderColor = isSelected ? selectedStateColor : normalStateColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard let style = buttonStyle else { return }
        // We need to call this method here because the background,
        // and the border color of the button when switching from dark to light mode
        // or vice versa can be updated only inside traitCollectionDidChange.
        applyStyleToNonDynamicProperties(style: style)
    }

    func setBackgroundImageColor(_ color: UIColor?, for state: UIControl.State) {
        if let color = color {
            setBackgroundImage(UIImage.singlePixelImage(with: color.resolvedColor(with: traitCollection)), for: state)
        } else {
            setBackgroundImage(nil, for: state)
        }
    }

}
