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

import Cartography
import UIKit

struct ModalPresentationConfiguration {
    let alpha: CGFloat
    let duration: TimeInterval
}

fileprivate extension UIViewControllerContextTransitioning {
    func complete(_ success: Bool) {
        completeTransition(!transitionWasCancelled)
    }
}

final private class ModalPresentationTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let configuration: ModalPresentationConfiguration

    init(configuration: ModalPresentationConfiguration) {
        self.configuration = configuration
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return configuration.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? ModalPresentationViewController else { preconditionFailure("No ModalPresentationViewController") }

        transitionContext.containerView.addSubview(toVC.view)
        toVC.view.layoutIfNeeded()

        let animations = { [configuration] in
            toVC.dimView.backgroundColor = .init(white: 0, alpha: configuration.alpha)
            toVC.viewController.view.transform  = .identity
        }

        if !transitionContext.isAnimated {
            return transitionContext.complete(true)
        }

        toVC.viewController.view.transform = CGAffineTransform(translationX: 0, y: toVC.viewController.view.bounds.height)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseInOut,
            animations: animations,
            completion: transitionContext.complete
        )
    }

}

final private class ModalDismissalTransition: NSObject, UIViewControllerAnimatedTransitioning {

    private let configuration: ModalPresentationConfiguration

    init(configuration: ModalPresentationConfiguration) {
        self.configuration = configuration
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return configuration.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? ModalPresentationViewController else { preconditionFailure("No ModalPresentationViewController") }
        guard let toVC = transitionContext.viewController(forKey: .to) else { preconditionFailure("No view controller to present") }

        let animations = {
            toVC.view.transform  = .identity
            fromVC.viewController.view.transform = CGAffineTransform(translationX: 0, y: fromVC.viewController.view.bounds.height)
            fromVC.dimView.backgroundColor = .clear
        }

        if !transitionContext.isAnimated {
            animations()
            return transitionContext.complete(true)
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: transitionContext.isInteractive ? configuration.duration : 0,
            options: [.curveLinear, .allowUserInteraction],
            animations: animations) { success in
                transitionContext.complete(success)
        }
    }

}

final private class ModalInteractionController: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var presentationViewController: ModalPresentationViewController!

    func setupWith(viewController: ModalPresentationViewController) {
        presentationViewController = viewController
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGestureRecognizer.maximumNumberOfTouches = 1
        viewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func didPan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!.superview!)
        var progress = (translation.y / presentationViewController.viewController.view.bounds.height)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))

        switch sender.state {
        case .began:
            interactionInProgress = true
            presentationViewController.dismiss(animated: true)
        case .changed:
            shouldCompleteTransition = progress > 0.2
            update(progress)
        case .cancelled:
            interactionInProgress = false
            cancel()
        case .ended:
            interactionInProgress = false
            !shouldCompleteTransition ? cancel() : finish()
        default: break
        }
    }

}

final class ModalPresentationViewController: UIViewController, UIViewControllerTransitioningDelegate {

    fileprivate unowned let viewController: UIViewController
    fileprivate let dimView = UIView()

    private let interactionController = ModalInteractionController()
    private let configuration: ModalPresentationConfiguration

    init(viewController: UIViewController,
         configuration: ModalPresentationConfiguration = .init(alpha: 0.3, duration: 0.3),
         enableDismissOnPan: Bool = true) {
        self.viewController = viewController
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        setupViews(with: viewController, enableDismissOnPan: enableDismissOnPan)
        createConstraints()
        modalPresentationCapturesStatusBarAppearance = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var childForStatusBarStyle: UIViewController? {
        return viewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return viewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private func setupViews(with viewController: UIViewController, enableDismissOnPan: Bool) {
        transitioningDelegate = self
        if enableDismissOnPan {
            interactionController.setupWith(viewController: self)
        }
        modalPresentationStyle = .overFullScreen
        view.addSubview(dimView)
        dimView.backgroundColor = .clear
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDimView)))
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    private func createConstraints() {
        constrain(view, viewController.view, dimView) { view, childViewControllerView, dimView in
            childViewControllerView.edges == view.edges
            dimView.edges == view.edges
        }
    }

    @objc
    private func didTapDimView(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalPresentationTransition(configuration: configuration)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalDismissalTransition(configuration: configuration)
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController.interactionInProgress ? interactionController : nil
    }

}
