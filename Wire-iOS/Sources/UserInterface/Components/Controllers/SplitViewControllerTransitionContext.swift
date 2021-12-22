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

final class SplitViewControllerTransitionContext: NSObject, UIViewControllerContextTransitioning {

    var completionBlock: ((_ didComplete: Bool) -> Void)?
    var isAnimated = false
    var isInteractive = false
    let containerView: UIView
    var presentationStyle: UIModalPresentationStyle = .custom

    private var viewControllers: [UITransitionContextViewControllerKey: UIViewController] = [:]

    init(from fromViewController: UIViewController?,
         to toViewController: UIViewController?,
         containerView: UIView) {
        self.containerView = containerView

        super.init()

        if fromViewController != nil {
            viewControllers[.from] = fromViewController
        }

        if toViewController != nil {
            viewControllers[.to] = toViewController
        }
    }

    func initialFrame(for viewController: UIViewController) -> CGRect {
        return containerView.bounds
    }

    func finalFrame(for viewController: UIViewController) -> CGRect {
        return containerView.bounds
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return viewControllers[key]
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {

        let transitionContextViewControllerKey: UITransitionContextViewControllerKey
        switch key {
        case .to:
            transitionContextViewControllerKey = .to
        case .from:
            transitionContextViewControllerKey = .from
        default:
            return nil
        }

        return viewControllers[transitionContextViewControllerKey]?.view
    }

    func completeTransition(_ didComplete: Bool) {
        completionBlock?(didComplete)
    }

    var transitionWasCancelled: Bool {
        return false
        // Our non-interactive transition can't be cancelled (it could be interrupted, though)
    }

    // Supress warnings by implementing empty interaction methods for the remainder of the protocol:
    var targetTransform: CGAffineTransform {
        return .identity
    }

    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        // no-op
    }

    func finishInteractiveTransition() {
        // no-op
    }

    func cancelInteractiveTransition() {
        // no-op
    }

    func pauseInteractiveTransition() {
        // no-op
    }

}
