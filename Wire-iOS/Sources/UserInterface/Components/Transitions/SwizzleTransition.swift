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

enum SwizzleTransitionDirection {
    case horizontal
    case vertical
}

final class SwizzleTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let direction: SwizzleTransitionDirection

    init(direction: SwizzleTransitionDirection) {
        self.direction = direction
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toView = transitionContext.toView
        let fromView = transitionContext.fromView

        let containerView = transitionContext.containerView

        if let toView = toView {
            containerView.addSubview(toView)
        }

        if !transitionContext.isAnimated {
            transitionContext.completeTransition(true)
            return
        }

        containerView.layoutIfNeeded()

        let durationPhase1: TimeInterval
        let durationPhase2: TimeInterval

        let verticalTransform = CGAffineTransform(translationX: 0, y: 48)

        if direction == .horizontal {
            toView?.transform = CGAffineTransform(translationX: 24, y: 0)
            durationPhase1 = 0.15
            durationPhase2 = 0.55
        } else {
            toView?.transform = verticalTransform
            durationPhase1 = 0.10
            durationPhase2 = 0.30
        }
        toView?.alpha = 0

        UIView.animate(easing: .easeInQuad, duration: durationPhase1, animations: {
            fromView?.alpha = 0
            fromView?.transform = self.direction == .horizontal ? CGAffineTransform(translationX: 48, y: 0) : verticalTransform
        }) { finished in
            UIView.animate(easing: .easeOutQuad, duration: durationPhase2, animations: {
                toView?.transform = .identity
                toView?.alpha = 1
            }) { finished in
                fromView?.transform = .identity
                transitionContext.completeTransition(true)
            }
        }
    }
}
