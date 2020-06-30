
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension UIView {
        
    /// The reason why we are touching the window here is to workaround a bug where,
    /// We now force the window to be the key window and to be the first responder to ensure that we can
    /// show the menu controller.
    /// ref: https://stackoverflow.com/questions/59176844/uimenucontroller-is-not-visible-in-ios-13-2/62578001#62578001
    func prepareShowingMenu() {
        window?.makeKey()
        window?.becomeFirstResponder()
        becomeFirstResponder()
    }
}

extension UIViewController {
    
    func prepareShowingMenu() {
        view.prepareShowingMenu()
        becomeFirstResponder()
    }
}
