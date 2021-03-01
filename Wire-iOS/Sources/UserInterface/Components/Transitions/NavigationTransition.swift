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

final class NavigationTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let operation: UINavigationController.Operation

    init?(operation: UINavigationController.Operation) {
        guard operation == .push || operation == .pop else { return nil }
        self.operation = operation

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.55
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.fromView,
            let toView = transitionContext.toView,
            let fromViewController = transitionContext.fromViewController,
            let toViewController = transitionContext.toViewController else {
                return
        }

        let containerView = transitionContext.containerView

        let initialFrameFromViewController = transitionContext.initialFrame(for: fromViewController)
        let finalFrameToViewController = transitionContext.finalFrame(for: toViewController)

        let offscreenRight = CGAffineTransform(translationX: initialFrameFromViewController.size.width, y: 0)
        let offscreenLeft = CGAffineTransform(translationX: -(initialFrameFromViewController.size.width), y: 0)

        let toViewStartTransform: CGAffineTransform
        let fromViewEndTransform: CGAffineTransform

        switch operation {
        case .push:
            toViewStartTransform = rightToLeft ? offscreenLeft : offscreenRight
            fromViewEndTransform = rightToLeft ? offscreenRight : offscreenLeft
        case .pop:
            toViewStartTransform = rightToLeft ? offscreenRight : offscreenLeft
            fromViewEndTransform = rightToLeft ? offscreenLeft : offscreenRight
        default:
            return
        }

        fromView.frame = initialFrameFromViewController
        toView.frame = finalFrameToViewController
        toView.transform = toViewStartTransform

        containerView.addSubview(toView)
        containerView.addSubview(fromView)

        containerView.layoutIfNeeded()

        UIView.animate(easing: .easeOutExpo,
                          duration: transitionDuration(using: transitionContext),
                          animations: {
            fromView.transform = fromViewEndTransform
            toView.transform = .identity
        }) { _ in
            fromView.transform = .identity
            transitionContext.completeTransition(true)
        }
    }

    private var rightToLeft: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
}
