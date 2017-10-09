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

import UIKit

extension UIScreen {
    
    static var safeArea: UIEdgeInsets {
        if #available(iOS 11, *) {
            if let window = UIApplication.shared.keyWindow {
                let insets = window.safeAreaInsets
                if insets.top > 0 {
                    return insets
                } else {
                    return UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
                }
            }
        }
        return UIEdgeInsets.zero
    }
    
    static var navbarHeight : CGFloat {
        if #available(iOS 11, *) {
            return 44.0
        } else {
            return 64.0
        }
    }
    
}
