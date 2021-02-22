//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

final class KeyboardBlockObserver: NSObject {

    struct ChangeInfo {
        enum Kind {
            case show, hide, change
        }

        let frame: CGRect
        let animationDuration: TimeInterval
        let kind: Kind
        let isKeyboardCollapsed: Bool?

        init?(_ note: Notification, kind: Kind) {
            guard let info = note.userInfo else { return nil }
            guard let endFrameValue = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return nil }
            frame = endFrameValue
            animationDuration = duration
            self.kind = kind

            if let beginFrameValue = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                /// key board is collapsed if init height is 0 or its is out of the screen bound
                if endFrameValue.height == 0 ||
                    endFrameValue.minY >= UIScreen.main.bounds.maxY ||
                    (endFrameValue == beginFrameValue &&
                     beginFrameValue.maxY > UIScreen.main.bounds.maxY &&
                     beginFrameValue.origin.y == UIScreen.main.bounds.maxY)
                    {
                    isKeyboardCollapsed = true
                } else {
                    isKeyboardCollapsed = beginFrameValue.height > endFrameValue.height && kind == .hide
                }
            } else {
                isKeyboardCollapsed = nil
            }
        }
    }

    typealias ChangeBlock = (ChangeInfo) -> Void

    private let changeBlock: ChangeBlock

    init(block: @escaping ChangeBlock) {
        self.changeBlock = block
        super.init()
        registerKeyboardObservers()
    }

    private func registerKeyboardObservers() {
        let center = NotificationCenter.default

        center.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ note: Notification) {
        ChangeInfo(note, kind: .show).apply(changeBlock)
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        ChangeInfo(note, kind: .hide).apply(changeBlock)
    }

    @objc private func keyboardWillChangeFrame(_ note: Notification) {
        ChangeInfo(note, kind: .change).apply(changeBlock)
    }

}
