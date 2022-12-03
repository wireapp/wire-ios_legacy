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
import WireCommonComponents

class CallingActionButton: IconLabelButton {

    override init(input: IconLabelButtonInput) {
        super.init(input: input)

        subtitleTransformLabel.text = input.label
        subtitleTransformLabel.textTransform = .capitalize
        titleLabel?.font = DynamicFontLabel(fontSpec: .smallRegularFont, color: .sectionText).font
        subtitleTransformLabel.font = titleLabel?.font

    }

    override func apply(_ configuration: CallActionAppearance) {
        iconButton.borderWidth = 1

        setTitleColor(configuration.textColorNormal, for: .normal)
        //iconButton.layer.borderColor = SemanticColors.Button.borderCallingNormal.cgColor
        iconButton.setBorderColor(SemanticColors.Button.borderCallingNormal, for: .normal)
        iconButton.setIconColor(SemanticColors.Button.iconCallingNormal, for: .normal)
        iconButton.setBackgroundImageColor(SemanticColors.Button.backgroundCallingNormal, for: .normal)
        //        iconButton.setBorderColor(configuration.borderColorNormal, for: .normal)
        //        iconButton.setIconColor(configuration.iconColorNormal, for: .normal)
        //        iconButton.setBackgroundImageColor(configuration.backgroundColorNormal, for: .normal)

        setTitleColor(configuration.textColorNormal, for: .selected)
        iconButton.setBorderColor(/*SemanticColors.Button.borderCallingSelected*/ .yellow, for: .selected)
        iconButton.setIconColor(SemanticColors.Button.iconCallingSelected, for: .selected)
        iconButton.setBackgroundImageColor(SemanticColors.Button.backgroundCallingSelected, for: .selected)
        //        iconButton.setBorderColor(configuration.borderColorSelected, for: .selected)
        //        iconButton.setIconColor(configuration.iconColorSelected, for: .selected)
        //        iconButton.setBackgroundImageColor(configuration.backgroundColorSelected, for: .selected)


        setTitleColor(configuration.textColorDisabled, for: .disabled)
        iconButton.setBorderColor(SemanticColors.Button.borderCallingDisabled, for: .disabled)
        iconButton.setIconColor(SemanticColors.Button.iconCallingDisabled, for: .disabled)
        iconButton.setBackgroundImageColor(SemanticColors.Button.backgroundCallingDisabled, for: .disabled)
        //        iconButton.setIconColor(configuration.iconColorDisabled, for: .disabled)
        //        iconButton.setBackgroundImageColor(configuration.backgroundColorDisabled, for: .disabled)
        //        iconButton.setBorderColor(configuration.borderColorDisabled, for: .disabled)
    }

}

class EndCallButton: CallingActionButton {

    override func apply(_ configuration: CallActionAppearance) {
        let redColor = SemanticColors.Button.backgroundLikeHighlighted
        setTitleColor(SemanticColors.Button.textCallingNormal, for: .normal)
        iconButton.setIconColor(SemanticColors.View.backgroundDefaultWhite, for: .normal)
        iconButton.setBackgroundImageColor(redColor, for: .normal)
    }

}
