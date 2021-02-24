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

import UIKit


// This subclass is used for the legal text in the Welcome screen and the reset password text in the login screen
// Purpose of this class is to reduce the amount of duplicate code to set the default properties of this NSTextView. On the Mac client we are using something similar to also stop the user from being able to select the text (selection property needs to be enabled to make the NSLinkAttribute work on the string). We may want to add this in the future here as well
final class WebLinkTextView: UITextView {

    init() {
        super.init(frame: .zero, textContainer: nil)

        if #available(iOS 11.0, *) {
            textDragDelegate = self
        }

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {

        // WORKAROUND: isEditable needs to true on iOS 13 for links to be visible as an accessiblity element
        // and set to false in iOS 12 or earlier for links to be tappable.
        if #available(iOS 13.0, *) {
            isEditable = true
        } else {
            isEditable = false
        }

        isScrollEnabled = false
        bounces = false
        backgroundColor = UIColor.clear
        textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textContainer.lineFragmentPadding = 0
    }


    /// non-selectable textview
    override public var selectedTextRange: UITextRange? {
        get { return nil }
        set { /* no-op */ }
    }

    // Prevent double-tap to select 
    override var canBecomeFirstResponder: Bool {
        return false
    }

    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // Prevent long press to show the magnifying glass
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }

        super.addGestureRecognizer(gestureRecognizer)
    }
}


@available(iOS 11.0, *)
extension WebLinkTextView: UITextDragDelegate {

    public func textDraggableView(_ textDraggableView: UIView & UITextDraggable, itemsForDrag dragRequest: UITextDragRequest) -> [UIDragItem] {
        return []
    }

}
