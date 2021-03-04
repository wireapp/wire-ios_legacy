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

final class ZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private var interactionPoint = CGPoint.zero
    private var reversed = false

    init(interactionPoint: CGPoint, reversed: Bool) {
        super.init()

        self.interactionPoint = interactionPoint
        self.reversed = reversed
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.65
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

        fromView?.alpha = 1
        fromView?.layer.needsDisplayOnBoundsChange = false

        if reversed {

            UIView.animate(easing: .easeInExpo, duration: 0.35, animations: {
                fromView?.alpha = 0
                fromView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }) { _ in
                fromView?.transform = .identity
            }

            toView?.alpha = 0
            toView?.transform = CGAffineTransform(scaleX: 2, y: 2)

            UIView.animate(easing: .easeOutExpo, duration: 0.35, animations: {
                toView?.alpha = 1
                toView?.transform = .identity
            }) { _ in
                transitionContext.completeTransition(true)
            }
        } else {

            if let frame = fromView?.frame {
                fromView?.layer.anchorPoint = interactionPoint
                fromView?.frame = frame
            }

            UIView.animate(easing: .easeInExpo, duration: 0.35, animations: {
                fromView?.alpha = 0
                fromView?.transform = CGAffineTransform(scaleX: 2, y: 2)
            }) { _ in
                fromView?.transform = .identity
            }

            if let frame = toView?.frame {
                toView?.layer.anchorPoint = interactionPoint
                toView?.frame = frame
            }

            toView?.alpha = 0
            toView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

            UIView.animate(easing: .easeOutExpo, duration: 0.35, delayTime: 0.3, animations: {
                toView?.alpha = 1
                toView?.transform = .identity
            }) { _ in
                transitionContext.completeTransition(true)
            }
        }
    }
}
