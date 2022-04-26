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

// MARK: - UIViewController Extension

extension UIViewController {

    func redrawAllfonts() {
        view.redrawAllfonts()
    }

}

// MARK: - DynamicTypeCapable Protocol

/// Every view which conforms to that protocol has to implement a redrawFont method
protocol DynamicTypeCapable {
    /// In this method we set the font for our views
    func redrawFont()

}

// MARK: - UIView Extension

extension UIView {
    /// We're going through each view which is a DynamicTypeCapable
    /// and with we're calling the redrawFont method
    func redrawAllfonts() {
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
