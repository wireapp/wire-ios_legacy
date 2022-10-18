//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import WireCommonComponents
import UIKit

extension UIBarButtonItem {

    convenience init(icon: StyleKitIcon, style: UIBarButtonItem.Style = .plain, target: Any?, action: Selector?) {
        self.init(
            image: icon.makeImage(size: .tiny, color: UIColor.from(scheme: .textForeground)),
            style: style,
            target: target,
            action: action
        )
    }

    static func createCloseItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(icon: .cross, target: nil, action: nil)
        item.accessibilityIdentifier = "close"
        item.accessibilityLabel = "general.close".localized
        return item
    }

    static func createUpdatedCloseItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(icon: .cross, target: nil, action: nil)
        item.tintColor = SemanticColors.Icon.foregroundDefault
        item.accessibilityIdentifier = "close"
        item.accessibilityLabel = "general.close".localized
        return item
    }

    static func createNavigationBarButtonDoneItem(
        systemImage: Bool,
        target buttonTarget: Any?,
        action buttonAction: Selector?,
        font buttonFont: FontSpec = FontSpec.headerRegularFont) -> UIBarButtonItem {

            var rightBarButtonItem: UIBarButtonItem
            if systemImage {
                rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .done,
                    target: buttonTarget,
                    action: buttonAction)
            } else {
                rightBarButtonItem = UIBarButtonItem(
                    title: "general.done".localized,
                    style: .plain,
                    target: buttonTarget,
                    action: buttonAction)
            }

            let buttonStates: [UIControl.State] = [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved]

            if let buttonFont = buttonFont.font {
                buttonStates.forEach { buttonState in
                    rightBarButtonItem.setTitleTextAttributes(
                        [NSAttributedString.Key.font: buttonFont],
                        for: buttonState)
                }
            }
            return rightBarButtonItem
    }

    static func createNavigationBarEditItem(
        target buttonTarget: Any?,
        action buttonAction: Selector?,
        font buttonFont: FontSpec = FontSpec.headerRegularFont) -> UIBarButtonItem {
            let rightBarButtonItem = UIBarButtonItem(
                title: "general.edit".localized,
                style: .plain,
                target: buttonTarget,
                action: buttonAction)

            let buttonStates: [UIControl.State] = [.normal, .highlighted, .disabled, .selected, .focused, .application, .reserved]

            if let buttonFont = buttonFont.font {
                buttonStates.forEach { buttonState in
                    rightBarButtonItem.setTitleTextAttributes(
                        [NSAttributedString.Key.font: buttonFont],
                        for: buttonState)
                }
            }
            return rightBarButtonItem
    }
}
