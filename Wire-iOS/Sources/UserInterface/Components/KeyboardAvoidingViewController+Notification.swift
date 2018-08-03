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

extension KeyboardAvoidingViewController {
    @objc func keyboardFrameWillChange(_ notification: Notification?) {
        if #available(iOS 10.0, *) {
            guard let duration = notification?.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
                  let curveRawValue = notification?.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
                  let animationCurve = UIViewAnimationCurve(rawValue: curveRawValue) else { return }

            let keyboardFrameInView = UIView.keyboardFrame(in: self.view, forKeyboardNotification: notification)
            let bottomOffset: CGFloat = -keyboardFrameInView.size.height

            guard self.bottomEdgeConstraint.constant != bottomOffset else {
                return
            }

            animator?.stopAnimation(true)

            self.bottomEdgeConstraint.constant = bottomOffset
            self.view.setNeedsLayout()
            animator = UIViewPropertyAnimator(duration: duration, curve: animationCurve, animations: {
                    self.view.layoutIfNeeded()
            })

            animator?.addCompletion { [weak self] _ in
                self?.animator = nil
            }
            animator?.startAnimation()

        } else {
            UIView.animate(withKeyboardNotification: notification,
                           in: view,
                           animations: { keyboardFrameInView in
                            let bottomOffset: CGFloat = -keyboardFrameInView.size.height
                            if self.bottomEdgeConstraint.constant != bottomOffset {
                                self.bottomEdgeConstraint.constant = bottomOffset
                                self.view.layoutIfNeeded()
                            }
                           },
                           completion: nil)
        }
    }
}

