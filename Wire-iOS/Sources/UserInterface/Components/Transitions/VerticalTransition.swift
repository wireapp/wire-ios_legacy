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

import Foundation
import UIKit

protocol VerticalTransitionDataSource: NSObject {
    func viewsToHideDuringVerticalTransition(transition: VerticalTransition) -> [UIView]
}

final class VerticalTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let offset: CGFloat
    weak var dataSource: VerticalTransitionDataSource?

    init(offset: CGFloat) {
        self.offset = offset

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.55
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView

        guard let toView = transitionContext.toView,
              let toViewController = transitionContext.toViewController else { return }

        guard let fromView = transitionContext.fromView,
              let fromViewController = transitionContext.fromViewController else { return }

        fromView.frame = transitionContext.initialFrame(for: fromViewController)

        containerView.addSubview(toView)

        if !transitionContext.isAnimated {
            transitionContext.completeTransition(true)
            return
        }

        containerView.layoutIfNeeded()

        let sign = copysign(1.0, self.offset)
        let finalRect = transitionContext.finalFrame(for: toViewController)
        let toTransfrom = CGAffineTransform(translationX: 0, y: -self.offset)
        let fromTransform = CGAffineTransform(translationX: 0, y: sign * (finalRect.size.height - abs(self.offset)))

        toView.transform = toTransfrom
        fromView.transform = fromTransform

        if let viewsToHide = dataSource?.viewsToHideDuringVerticalTransition(transition: self) {
            viewsToHide.forEach { $0.isHidden = true }
        }

        UIView.animate(easing: EasingFunction.easeOutExpo, duration: transitionDuration(using: transitionContext), animations: {
            fromView.transform = CGAffineTransform(translationX: 0.0, y: sign * finalRect.size.height)
            toView.transform = CGAffineTransform.identity
        }) { _ in
            fromView.transform = CGAffineTransform.identity
            if let viewsToHide = self.dataSource?.viewsToHideDuringVerticalTransition(transition: self) {
                viewsToHide.forEach { $0.isHidden = false }
            }

            transitionContext.completeTransition(true)
        }
    }
}
