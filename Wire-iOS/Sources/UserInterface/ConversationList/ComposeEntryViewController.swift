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
    case conversation = 1, message = 2
}


@objc class ComposeEntryViewController: UIViewController, UIViewControllerTransitioningDelegate {

    fileprivate let plusButton = IconButton()
    fileprivate let plusButtonContainer = UIView()
    fileprivate let conversationButton = IconButton()
    fileprivate let messageButton = IconButton.iconButtonCircularLight()
    fileprivate let dimView = UIView()

    fileprivate let messageLabel = ButtonWithLargerHitArea()
    fileprivate let conversationLabel = ButtonWithLargerHitArea()

    fileprivate let dimViewColor = UIColor(white: 0, alpha: 0.8)

    private enum ButtonState {
        case initial, expanded, final
    }

    private var messageButtonState: ButtonState = .initial {
        didSet {
            updateLeftButtonConstraints()
        }
    }

    private var conversationButtonState: ButtonState = .initial {
        didSet {
            updateRightButtonConstraints()
        }
    }

    private var messageInitialConstraints = [NSLayoutConstraint]()
    private var conversationInitialConstraints = [NSLayoutConstraint]()
    private var messageExpandedConstraints = [NSLayoutConstraint]()
    private var conversationExpandedConstraints = [NSLayoutConstraint]()
    private var messageFinalConstraints = [NSLayoutConstraint]()
    private var conversationFinalConstraints = [NSLayoutConstraint]()

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
        updateLeftButtonConstraints()
        updateRightButtonConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        dimView.backgroundColor = dimViewColor
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissController)))
        let titleColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
        conversationLabel.setTitleColor(titleColor, for: .normal)
        messageLabel.setTitleColor(titleColor, for: .normal)
        conversationLabel.titleLabel?.font = FontSpec(.small, .semibold).font!
        messageLabel.titleLabel?.font = FontSpec(.small, .semibold).font!
        messageLabel.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        conversationLabel.addTarget(self, action: #selector(conversationTapped), for: .touchUpInside)
        conversationLabel.setTitle("compose.contact.title".localized, for: .normal)
        messageLabel.setTitle("compose.message.title".localized, for: .normal)
        conversationButton.accessibilityIdentifier = "contactButton"
        messageButton.accessibilityIdentifier = "messageButton"
        conversationButton.backgroundColor = .white
        conversationButton.circular = true
        conversationButton.setIcon(.person, with: .tiny, for: .normal)
        conversationButton.setIconColor(.accent(), for: .normal)
        conversationButton.addTarget(self, action: #selector(conversationTapped), for: .touchUpInside)
        messageButton.backgroundColor = .accent()
        messageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
        messageButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        messageButton.setIcon(.compose, with: .tiny, for: .normal)
        plusButton.setIcon(.plus, with: .tiny, for: .normal)
        plusButton.setIconColor(.white, for: .normal)
        plusButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        plusButtonContainer.addSubview(plusButton)
        [dimView, plusButtonContainer, conversationButton, messageButton, messageLabel, conversationLabel].forEach(view.addSubview)
    }

    private func createConstraints() {
        let composeOffset = CGVector(offsetWithRadius: 100, angle: -75)
        let contactOffset = CGVector(offsetWithRadius: 100, angle: -15)

        constrain(view, plusButtonContainer, conversationButton, messageButton, plusButton) { view, plusButtonContainer, conversationButton, messageButton, plusButton in
            plusButtonContainer.bottom == view.bottom
            plusButtonContainer.leading == view.leading
            plusButtonContainer.height == 56

            messageButton.height == 50
            messageButton.width == 50
            conversationButton.height == 50
            conversationButton.width == 50

            self.messageExpandedConstraints = [
                messageButton.leading == plusButton.leading + composeOffset.dx,
                messageButton.centerY == plusButton.centerY + composeOffset.dy
            ]

            self.conversationExpandedConstraints = [
                conversationButton.leading == plusButton.leading + contactOffset.dx,
                conversationButton.centerY == plusButton.centerY + contactOffset.dy
            ]

            self.messageInitialConstraints = [
                messageButton.centerX == plusButton.centerX,
                messageButton.centerY == plusButton.centerY
            ]

            self.conversationInitialConstraints = [
                conversationButton.centerX == plusButton.centerX,
                conversationButton.centerY == plusButton.centerY
            ]

            self.messageFinalConstraints = [
                messageButton.leading == plusButton.leading + composeOffset.dx + 10,
                messageButton.centerY == view.bottom
            ]

            self.conversationFinalConstraints = [
                conversationButton.leading == plusButton.leading + contactOffset.dx + 10,
                conversationButton.centerY == view.bottom
            ]
        }

        constrain(view, dimView, plusButton, plusButtonContainer) { view, dimmView, plusButton, plusButtonContainer in
            dimmView.edges == view.edges
            plusButton.centerY == plusButtonContainer.centerY
            plusButton.leading == plusButtonContainer.leading + 16
            plusButton.trailing == plusButtonContainer.trailing - 18
        }

        constrain(messageLabel, messageButton, conversationLabel, conversationButton) { messageLabel, messageButton, contactsLabel, conversationButton in
            messageLabel.leading == messageButton.trailing + 12
            messageLabel.centerY == messageButton.centerY
            contactsLabel.leading == conversationButton.trailing + 12
            contactsLabel.centerY == conversationButton.centerY
        }
    }

    private func updateLeftButtonConstraints() {
        messageFinalConstraints.forEach { $0.isActive = messageButtonState == .final }
        messageInitialConstraints.forEach { $0.isActive = messageButtonState == .initial }
        messageExpandedConstraints.forEach { $0.isActive = messageButtonState == .expanded }
    }

    private func updateRightButtonConstraints() {
        conversationFinalConstraints.forEach { $0.isActive = conversationButtonState == .final }
        conversationInitialConstraints.forEach { $0.isActive = conversationButtonState == .initial }
        conversationExpandedConstraints.forEach { $0.isActive = conversationButtonState == .expanded }
    }

    private dynamic func dismissController() {
        onDismiss?(self)
    }

    private dynamic func conversationTapped() {
        onAction?(self, .conversation)
    }

    private dynamic func messageTapped() {
        onAction?(self, .message)
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
            let actionButtons = [toViewController.conversationButton, toViewController.messageButton]
            let actionLabels = [toViewController.conversationLabel, toViewController.messageLabel]

            // Prepare initial state
            toViewController.dimView.backgroundColor = .clear
            fromViewController.bottomBarController.plusButton.alpha = 0

            actionButtons.forEach {
                $0.transform = .scaledRotated
                $0.alpha = 0
            }
            actionLabels.forEach {
                $0.alpha = 0
                $0.transform = CGAffineTransform(translationX: -10, y: 0)
            }

            // Animate transition
            let totalDuration = transitionDuration(using: transitionContext)
            let animationGroup = DispatchGroup()

            UIView.animate(withDuration: totalDuration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                animationGroup.enter()
                toViewController.plusButton.transform = .rotation(degrees: 45)
            }, completion: { _ in
                animationGroup.leave()
            })

            // Update active constraints
            toViewController.messageButtonState = .expanded

            let (duration, delay) = totalDuration.split(by: 0.8)
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { 
                animationGroup.enter()
                toViewController.view.layoutIfNeeded()
            }, completion: { _ in
                animationGroup.leave()
            })

            // Update active constraints
            toViewController.conversationButtonState = .expanded

            UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut, animations: {
                animationGroup.enter()
                toViewController.view.layoutIfNeeded()
            }, completion: { _ in
                animationGroup.leave()
            })

            UIView.animate(withDuration: totalDuration.split(by: 0.5).0, delay: 0, options: .curveEaseOut, animations: {
                animationGroup.enter()
                toViewController.dimView.backgroundColor = toViewController.dimViewColor
                toViewController.messageButton.alpha = 1
                toViewController.messageButton.transform = .identity
            }, completion: { _ in
                animationGroup.leave()
            })

            UIView.animate(withDuration: totalDuration.split(by: 0.5).0, delay: delay, options: .curveEaseOut, animations: {
                animationGroup.enter()
                toViewController.conversationButton.alpha = 1
                toViewController.conversationButton.transform = .identity
            }, completion: { _ in
                animationGroup.leave()
            })

            let (labelDuration, labelDelay) = totalDuration.split(by: 0.8)
            UIView.animate(withDuration: labelDuration, delay: labelDelay, options: .curveEaseOut, animations: {
                animationGroup.enter()
                actionLabels.forEach {
                    $0.alpha = 1
                    $0.transform = .identity
                }
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

            // Prepare initial state
            let actionLabels = [fromViewController.conversationLabel, fromViewController.messageLabel]
            let animationGroup = DispatchGroup()
            let totalDuration = transitionDuration(using: transitionContext)

            // Animate transition
            UIView.animate(withDuration: totalDuration.split(by: 0.5).0, delay: 0, options: .curveEaseIn, animations: {
                animationGroup.enter()
                actionLabels.forEach {
                    $0.alpha = 0
                }
            }, completion: { _ in
                animationGroup.leave()
            })

            // Update active constraints
            fromViewController.messageButtonState = .final

            UIView.animate(withDuration: totalDuration, delay: 0, options: .curveEaseIn, animations: {
                animationGroup.enter()
                fromViewController.dimView.backgroundColor = .clear
                fromViewController.plusButton.transform = .identity
                fromViewController.view.layoutIfNeeded()
                fromViewController.messageButton.transform = .scaledRotated
                fromViewController.messageButton.alpha = 0
            }, completion: { _ in
                toViewController.bottomBarController.plusButton.alpha = 1
                animationGroup.leave()
            })

            // Update active constraints
            fromViewController.conversationButtonState = .final

            UIView.animate(withDuration: totalDuration * 0.7, delay: 0.1, options: .curveEaseIn, animations: {
                animationGroup.enter()
                fromViewController.view.layoutIfNeeded()
                fromViewController.conversationButton.transform = .scaledRotated
                fromViewController.conversationButton.alpha = 0
            }, completion: { _ in
                animationGroup.leave()
            })

            animationGroup.notify(queue: .main) {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
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

fileprivate extension TimeInterval {

    func split(by factor: CGFloat) -> (TimeInterval, TimeInterval) {
        precondition(factor > 0 && factor < 1)
        let lhs = self * TimeInterval(factor)
        return (lhs, self - lhs)
    }

}


fileprivate extension CGVector {

    init(offsetWithRadius radius: CGFloat, angle: CGFloat) {
        self.init(
            dx: radius * cos(angle.radians),
            dy: radius * sin(angle.radians)
        )
    }

}
