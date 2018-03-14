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

import Foundation

/**
 Marks a class which supports different color schemes.
 
 A themeable class should be redraw it self  when `colorSchemeVariant` is changed.
 
 **Note:**
 It is recommened that `colorSchemeVariant` is marked as a dynamic property
 in order for it work with `UIAppearance`.
 */
protocol Themeable {
    
    /// Color scheme variant which should be applied to the view
    var colorSchemeVariant : ColorSchemeVariant { get set }
    
    /// Applies a color scheme to a view
    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant)
    
}

extension UIView {
    
    /// Applies a color scheme to all subviews recursively.
    func applyColorSchemeOnSubviews(_ colorSchemeVariant: ColorSchemeVariant) {
        for subview in subviews {
            if let themable = subview as? Themeable {
                themable.applyColorScheme(colorSchemeVariant)
            }
            
            subview.applyColorSchemeOnSubviews(colorSchemeVariant)
        }
    }
    
}


