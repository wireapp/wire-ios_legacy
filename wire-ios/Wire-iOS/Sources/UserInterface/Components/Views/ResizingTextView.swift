//
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

import UIKit

class ResizingTextView: DragInteractionRestrictionTextView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: bounds.size.width, height: UIView.noIntrinsicMetric))
    }

    override func paste(_ sender: Any?) {
        super.paste(sender)

        // Work-around for text view scrolling too far when pasting text smaller
        // than the maximum height of the text view.
        setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
}
