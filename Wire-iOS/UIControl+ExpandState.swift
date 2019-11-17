//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension UIControl {
    /// Expand UIControl.State to its contained states
    ///
    /// - Parameters:
    ///   - state: the state to expand
    ///   - block: a closure with expanded state(s) as a argument
    @objc(expandState:block:)
    func expand(_ state: UIControl.State,
                block: @escaping (_ state: UIControl.State) -> Void) {
        if state == .normal {
            block(.normal)
        }
        
        if state.contains(.disabled) {
            block(.disabled)
        }
        
        if state.contains(.highlighted) {
            block(.highlighted)
        }
        
        if state.contains(.selected) {
            block(.selected)
        }
    }
}

