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

import UIKit

class CallQualityDismissalTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.55
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let callQualityVC = transitionContext.viewController(forKey: .from) as? CallQualityViewController else {
            return
        }

        let containerView = transitionContext.containerView
        let contentView = callQualityVC.contentView
        let dimmingView = callQualityVC.dimmingView

        // Animate Presentation

        let hideTransform: CGAffineTransform

        switch containerView.traitCollection.horizontalSizeClass {
        case .regular:
            hideTransform = CGAffineTransform(scaleX: 0, y: 0)

        default:
            hideTransform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        }

        let duration = transitionDuration(using: transitionContext)

        let animations = {
            dimmingView.alpha = 0
            contentView.transform = hideTransform
        }

        UIView.animate(withDuration: duration, delay: 0, options: .systemDismissalCurve, animations: animations) { finished in
            transitionContext.completeTransition((transitionContext.transitionWasCancelled == false) && finished)
        }

    }

}
