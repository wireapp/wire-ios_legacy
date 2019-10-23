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

    override open var childForStatusBarStyle: UIViewController? {
        return viewController
    }

    override open var childForStatusBarHidden: UIViewController? {
        return viewController
    }

    override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return viewController.preferredInterfaceOrientationForPresentation
    }

    @objc func keyboardFrameWillChange(_ notification: Notification?) {
        guard let bottomEdgeConstraint = bottomEdgeConstraint else { return }

        if let shouldAdjustFrame = shouldAdjustFrame, !shouldAdjustFrame(self) {
            bottomEdgeConstraint.constant = 0
            view.layoutIfNeeded()

            return
        }

        guard let userInfo = notification?.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        let keyboardFrameInView = UIView.keyboardFrame(in: self.view, forKeyboardNotification: notification)
        var bottomOffset: CGFloat = -abs(keyboardFrameInView.size.height)

        // When this controller's view is presented at a form sheet style on iPad, the view is has a top offset and the bottomOffset should be reduced.
        if modalPresentationStyle == .formSheet,
            let frame = presentationController?.frameOfPresentedViewInContainerView {

            bottomOffset += frame.minY
        }

        guard bottomEdgeConstraint.constant != bottomOffset else { return }
        
        // When the keyboard is dismissed and then quickly revealed again, then
        // the dismiss animation will be cancelled.
        animator?.stopAnimation(true)
        view.layoutIfNeeded()

        animator = UIViewPropertyAnimator(duration: duration, timingParameters: UISpringTimingParameters())

        animator?.addAnimations {
            bottomEdgeConstraint.constant = bottomOffset
            self.view.layoutIfNeeded()
        }
        
        animator?.addCompletion { [weak self] _ in
            self?.animator = nil
        }

        animator?.startAnimation()
    }

}
