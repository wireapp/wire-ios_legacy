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

import Foundation
import UIKit

/// This class is a drop-in replacement for UILabel which can be copied.
final class CopyableLabel: UILabel {

    private let dimmedAlpha: CGFloat = 0.4
    private let dimmAnimationDuration: TimeInterval = 0.33

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressed)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
    }

    @objc private func longPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began,
            let view = recognizer.view,
            let superview = view.superview,
            view == self,
            becomeFirstResponder() else { return }

        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: UIMenuController.didHideMenuNotification, object: nil)
        UIMenuController.shared.setTargetRect(view.frame, in: superview)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        fade(dimmed: true)
    }

    @objc private func menuDidHide(_ note: Notification) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.didHideMenuNotification, object: nil)
        fade(dimmed: false)
    }

    private func fade(dimmed: Bool) {
        UIView.animate(withDuration: dimmAnimationDuration) {
            self.alpha = dimmed ? self.dimmedAlpha : 1
        }
    }

}
