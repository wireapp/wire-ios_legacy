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

extension UIView {
    func popoverSourceRect(from viewController: UIViewController) -> CGRect {
        let sourceView: UIView = viewController.parent?.view ?? viewController.view

        // We want point to text of the textView instead of the oversized frame
        if self is UITextView {
            return sourceView.convert(CGRect(origin: frame.origin, size: intrinsicContentSize), from: superview)
        } else {
            return sourceView.convert(frame, from: superview)
        }
    }
}
