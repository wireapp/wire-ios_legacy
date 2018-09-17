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
        
        init?(_ note: Notification, kind: Kind) {
            guard let info = note.userInfo else { return nil }
            guard let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return nil }
            frame = frameValue.cgRectValue
            animationDuration = duration
            self.kind = kind
        }
        
        func animate(_ animations: @escaping () -> Void) {
            UIView.animate(withDuration: animationDuration, animations: animations)
        }
    }
    
    typealias ChangeBlock = (ChangeInfo) -> Void
    
    private let changeBlock: ChangeBlock
    private let center = NotificationCenter.default
    
    init(block: @escaping ChangeBlock) {
        self.changeBlock = block
        super.init()
        registerKeyboardObservers()
    }
    
    deinit {
        center.removeObserver(self)
    }
    
    private func registerKeyboardObservers() {
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
