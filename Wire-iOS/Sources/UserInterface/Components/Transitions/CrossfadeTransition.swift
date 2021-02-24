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

final class CrossfadeTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration: TimeInterval

    init(duration: TimeInterval = 0.35) {
        self.duration = duration
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toView = transitionContext.toView
        let fromView = transitionContext.fromView

        let containerView = transitionContext.containerView

        if let toView = toView {
            containerView.addSubview(toView)
        }

        if !transitionContext.isAnimated || duration == 0 {
            transitionContext.completeTransition(true)
            return
        }

        containerView.layoutIfNeeded()

        toView?.alpha = 0

        UIView.animate(easing: .easeInOutQuad, duration: duration, animations: {
            fromView?.alpha = 0
            toView?.alpha = 1
        }) { finished in
            transitionContext.completeTransition(true)
        }
    }
}
