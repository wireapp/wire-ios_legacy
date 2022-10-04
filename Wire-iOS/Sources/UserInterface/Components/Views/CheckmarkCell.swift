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

import UIKit
import WireCommonComponents

final class CheckmarkCell: RightIconDetailsCell {

    typealias BackgroundColors = SemanticColors.View

    var showCheckmark: Bool = false {
        didSet {
            updateCheckmark(forColor: ColorScheme.default.variant)

            titleBolded = showCheckmark
        }
    }

    override var disabled: Bool {
        didSet {
            updateCheckmark(forColor: ColorScheme.default.variant)
        }
    }

    override func setUp() {
        super.setUp()
        icon = nil
        status = nil

        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        accessibilityTraits = .button
    }

    override func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        super.applyColorScheme(colorSchemeVariant)
        updateCheckmark(forColor: colorSchemeVariant)
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? BackgroundColors.backgroundUserCellHightLighted
                : BackgroundColors.backgroundUserCell
        }
    }

    private func updateCheckmark(forColor colorSchemeVariant: ColorSchemeVariant) {

        guard showCheckmark else {
            accessory = nil
            return
        }

        let color: UIColor

        switch (colorSchemeVariant, disabled) {
        case (.light, false):
            color = SemanticColors.Icon.foregroundPlainCheckMark
        case (.light, true):
            color = UIColor.from(scheme: .textPlaceholder, variant: colorSchemeVariant)
        case (.dark, false):
            color = SemanticColors.Icon.foregroundPlainCheckMark
        case (.dark, true):
            color = UIColor.from(scheme: .textPlaceholder, variant: colorSchemeVariant)
        }

        accessory = StyleKitIcon.checkmark.makeImage(size: .tiny, color: color).withRenderingMode(.alwaysTemplate)
        accessoryColor = color
    }

    // MARK: - accessibility
    override var accessibilityLabel: String? {
        get {
            return title
        }

        set {
            // no op
        }
    }

    override var accessibilityValue: String? {
        get {
            return showCheckmark ? L10n.Accessibility.ConversationDetails.MessageTimeoutState.description : nil
        }

        set {
            // no op
        }
    }
}
