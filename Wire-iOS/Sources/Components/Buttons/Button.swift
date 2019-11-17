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

extension Button {
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        var title = title
        state.expand(block: { expandedState in
            if title != nil {
                self.originalTitles[NSNumber(value: expandedState.rawValue)] = title
            } else {
                self.originalTitles.removeObject(forKey: NSNumber(value: expandedState.rawValue))
            }
        })
        
        if textTransform != .none {
            title = title?.applying(transform: textTransform)
        }
        
        super.setTitle(title, for: state)
    }
    
    func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        state.expand(block: { state in
            if color != nil {
                self.borderColorByState[NSNumber(value: state.rawValue)] = color
            }
        })
        
        updateBorderColor()
    }
}
