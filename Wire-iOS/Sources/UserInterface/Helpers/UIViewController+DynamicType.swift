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

// MARK: - Helpers

extension UIViewController {

    func redrawAllFonts() {
        view.redrawAllFonts()
    }

}

// MARK: - DynamicTypeCapable Protocol

/// Objects conforming to this protocol opt in to react to changes of the preferred content size category
protocol DynamicTypeCapable {
    /// This method is called when the preferred content size category changes.
    /// Your implementation should update all of its fonts that are appropriately sized for the current content size category.
    func redrawFont()

}

// MARK: - UIView Extension

extension UIView {

    func redrawAllFonts() {
        visitSubviews { view in
            guard let dynamicTypeCapableView = view as? DynamicTypeCapable else { return }
            dynamicTypeCapableView.redrawFont()
        }
    }

    func visitSubviews(executing block: @escaping (UIView) -> Void) {
        for view in subviews {
            block(view)
            // go next layer down
            view.visitSubviews(executing: block)
        }
    }

}
