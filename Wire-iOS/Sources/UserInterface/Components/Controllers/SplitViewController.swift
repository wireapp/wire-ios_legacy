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

extension Notification.Name {
    static let SplitLayoutObservableDidChangeToLayoutSize = Notification.Name("SplitLayoutObservableDidChangeToLayoutSizeNotification")
}

enum SplitViewControllerTransition {
    case `default`
    case present
    case dismiss
}

enum SplitViewControllerLayoutSize {
    case compact
    case regularPortrait
    case regularLandscape
}

protocol SplitLayoutObservable: AnyObject {
    var layoutSize: SplitViewControllerLayoutSize { get }
    var leftViewControllerWidth: CGFloat { get }
}

protocol SplitViewControllerDelegate: AnyObject {
    func splitViewControllerShouldMoveLeftViewController(_ splitViewController: SplitViewController) -> Bool
}

final class SplitViewController: UIViewController, SplitLayoutObservable {
    weak var delegate: SplitViewControllerDelegate?

    // MARK: - SplitLayoutObservable
    var layoutSize: SplitViewControllerLayoutSize = .compact {
        didSet {
            guard oldValue != layoutSize else { return }

            NotificationCenter.default.post(name: Notification.Name.SplitLayoutObservableDidChangeToLayoutSize, object: self)
        }
    }

    var leftViewControllerWidth: CGFloat {
        return leftViewWidthConstraint?.constant ?? 0
    }

    var openPercentage: CGFloat = 0 {
        didSet {
            updateRightAndLeftEdgeConstraints(openPercentage)

            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var internalLeftViewController: UIViewController?
    var leftViewController: UIViewController? {
        get {
            return internalLeftViewController
        }

        set {
            setLeftViewController(newValue)
        }
    }

    var rightViewController: UIViewController?

    private var internalLeftViewControllerRevealed = true
    var isLeftViewControllerRevealed: Bool {
        get {
            return internalLeftViewControllerRevealed
        }

        set {
            internalLeftViewControllerRevealed = newValue

            updateLeftViewController(animated: true)
        }
    }

    var leftView: UIView = UIView(frame: UIScreen.main.bounds)
    var rightView: UIView = {
        let view = PlaceholderConversationView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.from(scheme: .background)

        return view
    }()

    private var leftViewLeadingConstraint: NSLayoutConstraint!
    private var rightViewLeadingConstraint: NSLayoutConstraint!
    private var leftViewWidthConstraint: NSLayoutConstraint!
    private var rightViewWidthConstraint: NSLayoutConstraint!
    private var sideBySideConstraint: NSLayoutConstraint!
    private var pinLeftViewOffsetConstraint: NSLayoutConstraint!

    private var horizontalPanner: UIPanGestureRecognizer = UIPanGestureRecognizer()

    private var futureTraitCollection: UITraitCollection?

    // MARK: - init
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        [leftView, rightView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        setupInitialConstraints()
        updateLayoutSize(for: traitCollection)
        updateConstraints(for: view.bounds.size)
        updateActiveConstraints()

        openPercentage = 1

        horizontalPanner.addTarget(self, action: #selector(onHorizontalPan(_:)))
        horizontalPanner.delegate = self
        view.addGestureRecognizer(horizontalPanner)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        futureTraitCollection = newCollection
        updateLayoutSize(for: newCollection)

        super.willTransition(to: newCollection, with: coordinator)

        updateActiveConstraints()

        updateLeftViewVisibility()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        update(for: view.bounds.size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        update(for: size)

        coordinator.animate(alongsideTransition: { _ in
        }, completion: { _ in
            self.updateLayoutSizeAndLeftViewVisibility()
        })

    }

    // MARK: - status bar
    private var childViewController: UIViewController? {
        return openPercentage > 0 ? leftViewController : rightViewController
    }

    override var childForStatusBarStyle: UIViewController? {
        return childViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return childViewController
    }

    // MARK: - animator
    var animatorForRightView: UIViewControllerAnimatedTransitioning {
        if layoutSize == .compact && isLeftViewControllerRevealed {
            // Right view is not visible so we should not animate.
            return CrossfadeTransition(duration: 0)
        } else if layoutSize == .regularLandscape {
            return SwizzleTransition(direction: .horizontal)
        }

        return CrossfadeTransition()
    }

    // MARK: - left and right view controllers
    func setLeftViewControllerRevealed(_ leftViewControllerRevealed: Bool,
                                       animated: Bool,
                                       completion: Completion? = nil) {
        self.internalLeftViewControllerRevealed = leftViewControllerRevealed
        updateLeftViewController(animated: animated, completion: completion)
    }

    func setRightViewController(_ newRightViewController: UIViewController?,
                                animated: Bool,
                                completion: Completion? = nil) {
        guard rightViewController != newRightViewController else {
            return
        }

        // To determine if self.rightViewController.presentedViewController is actually presented over it, or is it
        // presented over one of it's parents.
        if rightViewController?.presentedViewController?.presentingViewController == rightViewController {
            rightViewController?.dismiss(animated: false)
        }

        let transitionDidStart = transition(from: rightViewController,
                                            to: newRightViewController,
                                            containerView: rightView,
                                            animator: animatorForRightView,
                                            animated: animated,
                                            completion: completion)

        if transitionDidStart {
            rightViewController = newRightViewController
        }
    }

    func setLeftViewController(_ newLeftViewController: UIViewController?,
                               animated: Bool = false,
                               transition: SplitViewControllerTransition = .`default`,
                               completion: Completion? = nil) {
        guard leftViewController != newLeftViewController else {
            completion?()
            return
        }

        let animator: UIViewControllerAnimatedTransitioning

        if leftViewController == nil || newLeftViewController == nil {
            animator = CrossfadeTransition()
        } else if transition == .present {
            animator = VerticalTransition(offset: 88)
        } else if transition == .dismiss {
            animator = VerticalTransition(offset: -88)
        } else {
            animator = CrossfadeTransition()
        }

        if self.transition(from: leftViewController,
                           to: newLeftViewController,
                           containerView: leftView,
                           animator: animator,
                           animated: animated,
                           completion: completion) {
            internalLeftViewController = newLeftViewController
        }
    }

    var isConversationViewVisible: Bool {
        return layoutSize == .regularLandscape ||
               !isLeftViewControllerRevealed
    }

    /// update left view UI depends on isLeftViewControllerRevealed
    ///
    /// - Parameters:
    ///   - animated: animation enabled?
    ///   - completion: completion closure
    private func updateLeftViewController(animated: Bool, completion: Completion? = nil) {
        if animated {
            view.layoutIfNeeded()
        }
        leftView.isHidden = false

        resetOpenPercentage()
        if layoutSize != .regularLandscape {
            leftViewController?.beginAppearanceTransition(isLeftViewControllerRevealed, animated: animated)
            rightViewController?.beginAppearanceTransition(!isLeftViewControllerRevealed, animated: animated)
        }

        let completionBlock: Completion = {
            completion?()

            if self.openPercentage == 0 &&
                self.layoutSize != .regularLandscape &&
                (self.leftView.layer.presentation()?.frame == self.leftView.frame || (self.leftView.layer.presentation()?.frame == nil && !animated)) {
                self.leftView.isHidden = true
            }
        }

        if animated {
            UIView.animate(easing: .easeOutExpo, duration: 0.55, animations: {() -> Void in
                self.view.layoutIfNeeded()
            }, completion: {(_ finished: Bool) -> Void in
                if self.layoutSize != .regularLandscape {
                    self.leftViewController?.endAppearanceTransition()
                    self.rightViewController?.endAppearanceTransition()
                }
                completionBlock()
            })
        } else {
            completionBlock()
        }
    }

    // MARK: - update size

    /// return true if right view (mostly conversation screen) is fully visible
    var isRightViewControllerRevealed: Bool {
        switch self.layoutSize {
        case .compact, .regularPortrait:
            return !isLeftViewControllerRevealed
        case .regularLandscape:
            return true
        }
    }

    private var isiOSAppOnMac: Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }

        return false
    }

    /// Update layoutSize for the change of traitCollection and the current orientation
    ///
    /// - Parameters:
    ///   - traitCollection: the new traitCollection
    private func updateLayoutSize(for traitCollection: UITraitCollection) {

        switch (isiOSAppOnMac, traitCollection.horizontalSizeClass, UIWindow.interfaceOrientation?.isPortrait) {
        case (true, _, true), (false, .regular, false):
            layoutSize = .regularLandscape
        case (false, .regular, true):
            layoutSize = .regularPortrait
        default:
            layoutSize = .compact
        }
    }

    private func update(for size: CGSize) {
        updateLayoutSize(for: futureTraitCollection ?? traitCollection)

        updateConstraints(for: size)
        updateActiveConstraints()

        futureTraitCollection = nil

        // update right view constraits after size changes
        updateRightAndLeftEdgeConstraints(openPercentage)
    }

    private func updateLayoutSizeAndLeftViewVisibility() {
        updateLayoutSize(for: traitCollection)
        updateLeftViewVisibility()
    }

    private func updateLeftViewVisibility() {
        switch layoutSize {
        case .compact /* fallthrough */, .regularPortrait:
            leftView.isHidden = (openPercentage == 0)
        case .regularLandscape:
            leftView.isHidden = false
        }
    }

    private var constraintsActiveForCurrentLayout: [NSLayoutConstraint] {
        var constraints: Set<NSLayoutConstraint> = []

        if layoutSize == .regularLandscape {
            constraints.formUnion(Set([pinLeftViewOffsetConstraint, sideBySideConstraint]))
        }

        constraints.formUnion(Set([leftViewWidthConstraint]))

        return Array(constraints)
    }

    private var constraintsInactiveForCurrentLayout: [NSLayoutConstraint] {
        guard layoutSize != .regularLandscape else {
            return []
        }

        var constraints: Set<NSLayoutConstraint> = []
        constraints.formUnion(Set([pinLeftViewOffsetConstraint, sideBySideConstraint]))
        return Array(constraints)
    }

    private func transition(from fromViewController: UIViewController?,
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

        let transitionContext = SplitViewControllerTransitionContext(from: fromViewController,
                                                                     to: toViewController,
                                                                     containerView: containerView)

        transitionContext.isInteractive = false
        transitionContext.isAnimated = animated
        transitionContext.completionBlock = { _ in
            fromViewController?.view.removeFromSuperview()
            fromViewController?.removeFromParent()
            toViewController?.didMove(toParent: self)
            completion?()
        }

        animator?.animateTransition(using: transitionContext)

        return true
    }

    private func resetOpenPercentage() {
        openPercentage = isLeftViewControllerRevealed ? 1 : 0
    }

    private func updateRightAndLeftEdgeConstraints(_ percentage: CGFloat) {
        rightViewLeadingConstraint.constant = leftViewWidthConstraint.constant * percentage
        leftViewLeadingConstraint.constant = 64 * (1 - percentage)
    }

    // MARK: - constraints
    private func setupInitialConstraints() {

        leftViewLeadingConstraint = leftView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leftViewLeadingConstraint.priority = UILayoutPriority.defaultHigh
        rightViewLeadingConstraint = rightView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        rightViewLeadingConstraint.priority = UILayoutPriority.defaultHigh

        leftViewWidthConstraint = leftView.widthAnchor.constraint(equalToConstant: 0)
        rightViewWidthConstraint = rightView.widthAnchor.constraint(equalToConstant: 0)

        pinLeftViewOffsetConstraint = leftView.leftAnchor.constraint(equalTo: view.leftAnchor)
        sideBySideConstraint = rightView.leftAnchor.constraint(equalTo: leftView.rightAnchor)
        sideBySideConstraint.isActive = false

        let constraints: [NSLayoutConstraint] =
            [leftView.topAnchor.constraint(equalTo: view.topAnchor), leftView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
             rightView.topAnchor.constraint(equalTo: view.topAnchor), rightView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
             leftViewLeadingConstraint,
             rightViewLeadingConstraint,
             leftViewWidthConstraint,
             rightViewWidthConstraint,
             pinLeftViewOffsetConstraint]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateActiveConstraints() {
        NSLayoutConstraint.deactivate(constraintsInactiveForCurrentLayout)
        NSLayoutConstraint.activate(constraintsActiveForCurrentLayout)
    }

    private func leftViewMinWidth(size: CGSize) -> CGFloat {
        return min(size.width * 0.43, CGFloat.SplitView.LeftViewWidth)
    }

    private func updateConstraints(for size: CGSize, willMoveToEmptyView toEmptyView: Bool = false) {
        let isRightViewEmpty: Bool = rightViewController == nil || toEmptyView

        switch (layoutSize, isRightViewEmpty) {
        case (.compact, _):
            leftViewWidthConstraint.constant = size.width
            rightViewWidthConstraint.constant = size.width
        case (.regularPortrait, true),
             (.regularLandscape, _):
            leftViewWidthConstraint.constant = leftViewMinWidth(size: size)
            rightViewWidthConstraint.constant = size.width - leftViewWidthConstraint.constant
        case (.regularPortrait, false):
            leftViewWidthConstraint.constant = leftViewMinWidth(size: size)
            rightViewWidthConstraint.constant = size.width
        }
    }

    // MARK: - gesture

    @objc
    func onHorizontalPan(_ gestureRecognizer: UIPanGestureRecognizer?) {

        guard layoutSize != .regularLandscape,
            delegate?.splitViewControllerShouldMoveLeftViewController(self) == true,
            isConversationViewVisible,
            let gestureRecognizer = gestureRecognizer else {
                return
        }

        var offset = gestureRecognizer.translation(in: view)

        switch gestureRecognizer.state {
        case .began:
            leftViewController?.beginAppearanceTransition(!isLeftViewControllerRevealed, animated: true)
            rightViewController?.beginAppearanceTransition(isLeftViewControllerRevealed, animated: true)
            leftView.isHidden = false
        case .changed:
            if let width = leftViewController?.view.bounds.size.width {
                if offset.x > 0, view.isRightToLeft {
                    offset.x = 0
                } else if offset.x < 0, !view.isRightToLeft {
                    offset.x = 0
                } else if abs(offset.x) > width {
                    offset.x = width
                }
                openPercentage = abs(offset.x) / width
                view.layoutIfNeeded()
            }
        case .cancelled,
             .ended:
            let isRevealed = openPercentage > 0.5
            let didCompleteTransition = isRevealed != isLeftViewControllerRevealed

            setLeftViewControllerRevealed(isRevealed, animated: true) { [weak self] in
                if didCompleteTransition {
                    self?.leftViewController?.endAppearanceTransition()
                    self?.rightViewController?.endAppearanceTransition()
                }
            }
        default:
            break
        }
    }

}

extension SplitViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if layoutSize == .regularLandscape {
            return false
        }

        if let delegate = delegate, !delegate.splitViewControllerShouldMoveLeftViewController(self) {
            return false
        }

        if isLeftViewControllerRevealed && !isIPadRegular() {
            return false
        }

        return true
    }
}
