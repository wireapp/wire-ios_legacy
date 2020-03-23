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

extension SplitViewController {
    //MARK: - override
    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        futureTraitCollection = newCollection
        updateLayoutSize(for: newCollection)
        
        super.willTransition(to: newCollection, with: coordinator)
        
        updateActiveConstraints()
        
        updateLeftViewVisibility()
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        update(for: view.bounds.size)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        update(for: size)
        
        coordinator.animate(alongsideTransition: { context in
        }) { context in
            self.updateLayoutSizeAndLeftViewVisibility()
        }
        
    }

    //MARK: - status bar
    private var childViewController: UIViewController? {
        return openPercentage > 0 ? leftViewController : rightViewController
    }

    override open var childForStatusBarStyle: UIViewController? {
        return childViewController
    }

    override open var childForStatusBarHidden: UIViewController? {
        return childViewController
    }

    // MARK: - animator
    @objc
    var animatorForRightView: UIViewControllerAnimatedTransitioning? {
        if layoutSize == .compact && isLeftViewControllerRevealed {
            // Right view is not visible so we should not animate.
            return CrossfadeTransition(duration: 0)
        } else if layoutSize == .regularLandscape {
            return SwizzleTransition(direction: .horizontal)
        }

        return CrossfadeTransition()
    }

    @objc
    func setLeftViewController(_ leftViewController: UIViewController?,
                               animated: Bool,
                               transition: SplitViewControllerTransition = .`default`,
                               completion: Completion?) {
        if self.leftViewController == leftViewController {
            completion?()
            return
        }

        let removedViewController = self.leftViewController

        let animator: UIViewControllerAnimatedTransitioning

        if removedViewController == nil || leftViewController == nil {
            animator = CrossfadeTransition()
        } else if transition == .present {
            animator = VerticalTransition(offset: 88)
        } else if transition == .dismiss {
            animator = VerticalTransition(offset: -88)
        } else {
            animator = CrossfadeTransition()
        }

        if self.transition(from: removedViewController, to: leftViewController, containerView: leftView, animator: animator, animated: animated, completion: completion) {
            self.setInternalLeft(leftViewController)
        }
    }
    
    //TODO private
    
    
    var constraintsActiveForCurrentLayout: [NSLayoutConstraint] {
        var constraints: Set<NSLayoutConstraint> = []
        
        if layoutSize == .regularLandscape {
            constraints.formUnion(Set([pinLeftViewOffsetConstraint, sideBySideConstraint]))
        }
        
        constraints.formUnion(Set([leftViewWidthConstraint]))
        
        return Array(constraints)
    }
    
    var constraintsInactiveForCurrentLayout: [NSLayoutConstraint] {
        guard layoutSize != .regularLandscape else {
            return []
        }
        
        var constraints: Set<NSLayoutConstraint> = []
        constraints.formUnion(Set([pinLeftViewOffsetConstraint, sideBySideConstraint]))
        return Array(constraints)
    }

    //private
    @objc(transitionFromViewController:toViewController:containerView:animator:animated:completion:)
    func transition(from fromViewController: UIViewController?,
                            to toViewController: UIViewController?,
                            containerView: UIView,
                            animator: UIViewControllerAnimatedTransitioning?,
                            animated: Bool,
                            completion: Completion? = nil) -> Bool {
        // Return if transition is done or already in progress
        if let toViewController = toViewController, children.contains(toViewController) {
                return false
        }
        
        fromViewController?.willMove(toParent: nil)
        
        if let toViewController = toViewController {
            toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addChild(toViewController)
        } else {
            updateConstraints(for: view.bounds.size, willMoveToEmptyView: true)
        }
        
        ///TODO: non optional
        let transitionContext = SplitViewControllerTransitionContext(from: fromViewController, to: toViewController, containerView: containerView)!
        
        transitionContext.isInteractive = false
        transitionContext.isAnimated = animated
        transitionContext.completionBlock = { didComplete in
            fromViewController?.view.removeFromSuperview()
            fromViewController?.removeFromParent()
            toViewController?.didMove(toParent: self)
                completion?()
        }
        
        animator?.animateTransition(using: transitionContext)
        
        return true
    }

    @objc
    func resetOpenPercentage() {
        openPercentage = isLeftViewControllerRevealed ? 1 : 0
    }

    @objc
    func updateRightAndLeftEdgeConstraints(_ percentage: CGFloat) {
        rightViewLeadingConstraint.constant = leftViewWidthConstraint.constant * percentage
        leftViewLeadingConstraint.constant = 64 * (1 - percentage)
    }
    //TODO end of private

}
