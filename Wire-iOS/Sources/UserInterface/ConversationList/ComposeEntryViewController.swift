//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


@objc enum ComposeAction: UInt {
    case contacts = 1, drafts = 2
}


@objc class ComposeEntryViewController: UIViewController, UIViewControllerTransitioningDelegate {

    fileprivate let plusButton = IconButton()
    fileprivate let plusButtonContainer = UIView()
    fileprivate let contactsButton = IconButton()
    fileprivate let composeButton = IconButton.iconButtonCircularLight()
    fileprivate let dimmView = UIView()

    fileprivate let dimmViewColor = UIColor(white: 0, alpha: 0.5)

    var onDismiss: ((ComposeEntryViewController) -> Void)?
    var onAction: ((ComposeEntryViewController, ComposeAction) -> Void)?

    lazy var plusButtonAnchor: CGPoint = {
        return self.view.convert(self.plusButton.center, from: self.plusButtonContainer)
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
        transitioningDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        dimmView.backgroundColor = dimmViewColor
        dimmView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissController)))
        contactsButton.backgroundColor = .white
        contactsButton.circular = true
        contactsButton.setIcon(.person, with: .tiny, for: .normal)
        contactsButton.setIconColor(UIColor(for: .strongBlue), for: .normal)
        contactsButton.addTarget(self, action: #selector(contactsTapped), for: .touchUpInside)
        composeButton.backgroundColor = UIColor(for: .strongBlue)
        composeButton.addTarget(self, action: #selector(draftsTapped), for: .touchUpInside)
        composeButton.setIcon(.compose, with: .tiny, for: .normal)
        plusButton.setIcon(.plus, with: .tiny, for: .normal)
        plusButton.setIconColor(.white, for: .normal)
        plusButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        plusButtonContainer.addSubview(plusButton)
        [dimmView, plusButtonContainer, contactsButton, composeButton].forEach(view.addSubview)
    }

    private func createConstraints() {

        constrain(view, plusButtonContainer, contactsButton, composeButton) { view, plusButtonContainer, contactsButton, composeButton in
            plusButtonContainer.bottom == view.bottom
            plusButtonContainer.leading == view.leading
            plusButtonContainer.height == 56

            composeButton.height == 50
            composeButton.width == 50
            contactsButton.height == 50
            contactsButton.width == 50
        }

        constrain(view, dimmView, plusButton, plusButtonContainer) { view, dimmView, plusButton, plusButtonContainer in
            dimmView.edges == view.edges
            plusButton.centerY == plusButtonContainer.centerY
            plusButton.leading == plusButtonContainer.leading + 10
            plusButton.trailing == plusButtonContainer.trailing - 18
        }
    }

    private dynamic func dismissController() {
        onDismiss?(self)
    }

    private dynamic func contactsTapped() {
        onAction?(self, .contacts)
    }

    private dynamic func draftsTapped() {
        onAction?(self, .drafts)
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ComposeViewControllerPresentationTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ComposeViewControllerDismissalTransition()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    private class ComposeViewControllerPresentationTransition: NSObject, UIViewControllerAnimatedTransitioning {

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.4
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            guard let toViewController = transitionContext.viewController(forKey: .to) as? ComposeEntryViewController,
                let fromViewController = transitionContext.viewController(forKey: .from) as? ConversationListViewController else {
                    preconditionFailure("Transition can only be used from a ConversationListViewController to a ComposeEntryViewController")
            }

            if let toView = transitionContext.view(forKey: .to) {
                transitionContext.containerView.addSubview(toView)
                toView.layoutIfNeeded()
            }

            guard transitionContext.isAnimated else { return transitionContext.completeTransition(true) }

            // Prepare initial state
            toViewController.dimmView.backgroundColor = .clear
            toViewController.contactsButton.center = toViewController.plusButtonAnchor
            toViewController.composeButton.center = toViewController.plusButtonAnchor
            toViewController.contactsButton.transform = .scaledRotated
            toViewController.composeButton.transform = .scaledRotated
            toViewController.contactsButton.alpha = 0.2
            toViewController.composeButton.alpha = 0.2
            fromViewController.bottomBarController.plusButton.alpha = 0

            // Animate transition
            let totalDuration = transitionDuration(using: transitionContext)
            let animationGroup = DispatchGroup()

            UIView.animate(withDuration: totalDuration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                animationGroup.enter()
                // TODO: Use Autolayout and constraints to ensure RTL compatibility
                toViewController.contactsButton.center = toViewController.plusButtonAnchor.pointOnCircle(radius: 100, angle: -15)
                toViewController.composeButton.center = toViewController.plusButtonAnchor.pointOnCircle(radius: 100, angle: -75)
                toViewController.plusButton.transform = .rotation(degrees: 45)
                toViewController.view.layoutIfNeeded()
            }, completion: { _ in
                animationGroup.leave()
            })

            UIView.animate(withDuration: totalDuration * 0.5, delay: 0, options: .curveEaseOut, animations: {
                animationGroup.enter()
                toViewController.dimmView.backgroundColor = toViewController.dimmViewColor
                toViewController.contactsButton.alpha = 1
                toViewController.composeButton.alpha = 1
                toViewController.contactsButton.transform = .identity
                toViewController.composeButton.transform = .identity
            }, completion: { _ in
                animationGroup.leave()
            })
            
            animationGroup.notify(queue: .main) {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }

    }

    private class ComposeViewControllerDismissalTransition: NSObject, UIViewControllerAnimatedTransitioning {

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.25
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            guard let toViewController = transitionContext.viewController(forKey: .to) as? ConversationListViewController,
                let fromViewController = transitionContext.viewController(forKey: .from) as? ComposeEntryViewController else {
                    preconditionFailure("Transition can only be used from a ComposeEntryViewController to a ConversationListViewController")
            }

            if let toView = transitionContext.view(forKey: .to) {
                transitionContext.containerView.addSubview(toView)
                toView.layoutIfNeeded()
            }

            guard transitionContext.isAnimated else { return transitionContext.completeTransition(true) }

            // Animate transition
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseIn, animations: {
                fromViewController.dimmView.backgroundColor = .clear
                fromViewController.contactsButton.center = fromViewController.plusButtonAnchor
                fromViewController.composeButton.center = fromViewController.plusButtonAnchor
                fromViewController.contactsButton.transform = .scaledRotated
                fromViewController.composeButton.transform = .scaledRotated
                fromViewController.contactsButton.alpha = 0.2
                fromViewController.composeButton.alpha = 0.2
                fromViewController.plusButton.transform = .identity
            }, completion: { _ in
                toViewController.bottomBarController.plusButton.alpha = 1
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
        
    }
    
}


// MARK: Helper


fileprivate extension CGAffineTransform {

    static var scaledRotated: CGAffineTransform {
        return rotation(degrees: 30).concatenating(CGAffineTransform(scaleX: 0.7, y: 0.7))
    }

    static func rotation(degrees: CGFloat) -> CGAffineTransform {
        return CGAffineTransform(rotationAngle: degrees.radians)
    }

}

fileprivate extension CGFloat {

    var radians: CGFloat {
        return self * .pi / 180
    }

}


fileprivate extension CGPoint {

    func pointOnCircle(radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: x + radius * cos(angle.radians),
            y: y + radius * sin(angle.radians)
        )
    }

}
