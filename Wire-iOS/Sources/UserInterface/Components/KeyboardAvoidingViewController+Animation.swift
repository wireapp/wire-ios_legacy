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

extension UIViewAnimationCurve {
    init(rawValue: Int, fallbackValue: UIViewAnimationCurve) {
        self = UIViewAnimationCurve(rawValue: rawValue) ?? fallbackValue

        if #available(iOS 11.0, *) {
        } else {
            // iOS returns an undocumented type 7 animation curve raw value, which causes crashes on iOS 10 if it is used as an argument in UIViewPropertyAnimator init method. Workaround: assign a fallback value.

            if self != .easeInOut &&
                self != .easeIn &&
                self != .easeOut &&
                self != .linear {
                self = fallbackValue
            }
        }
    }
}

extension KeyboardAvoidingViewController {
    @objc func keyboardFrameWillChange(_ notification: Notification?) {
        guard let bottomEdgeConstraint = self.bottomEdgeConstraint else { return }

        if let shouldAdjustFrame = shouldAdjustFrame,
            !shouldAdjustFrame(self) {
            bottomEdgeConstraint.constant = 0
            view.layoutIfNeeded()
            return
        }

        // Using stoppable UIViewPropertyAnimator instead of UIView animation for iOS 10+. When the keyboard is dismissed and then revealed in a short time, the later earlier animation will be cancelled.
        if #available(iOS 10.0, *) {
            guard let duration = notification?.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
                let curveRawValue = notification?.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int else { return }

            let keyboardFrameInView = UIView.keyboardFrame(in: self.view, forKeyboardNotification: notification)
            let bottomOffset: CGFloat = -keyboardFrameInView.size.height

            guard bottomEdgeConstraint.constant != bottomOffset else { return }

            animator?.stopAnimation(true)

            bottomEdgeConstraint.constant = bottomOffset
            self.view.setNeedsLayout()


            animator = UIViewPropertyAnimator(duration: duration, curve: UIViewAnimationCurve(rawValue: curveRawValue, fallbackValue: .easeIn), animations: {
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
                            if bottomEdgeConstraint.constant != bottomOffset {
                                bottomEdgeConstraint.constant = bottomOffset
                                self.view.layoutIfNeeded()
                            }
                            },
                           completion: nil)
        }
    }
}
