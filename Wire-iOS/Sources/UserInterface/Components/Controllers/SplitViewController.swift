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

extension Notification.Name {
    static let SplitLayoutObservableDidChangeToLayoutSize = Notification.Name("SplitLayoutObservableDidChangeToLayoutSizeNotification")
}

enum SplitViewControllerTransition : Int {
    case `default`
    case present
    case dismiss
}

enum SplitViewControllerLayoutSize {
    case compact
    case regularPortrait
    case regularLandscape
}

protocol SplitLayoutObservable: class {
    var layoutSize: SplitViewControllerLayoutSize { get }
    var leftViewControllerWidth: CGFloat { get }
}

protocol SplitViewControllerDelegate: class {
    func splitViewControllerShouldMoveLeftViewController(_ splitViewController: SplitViewController) -> Bool
}

final class SplitViewController: UIViewController, SplitLayoutObservable {
    private var internalLeftViewController: UIViewController?
    var leftViewController: UIViewController? {
        get{
            return internalLeftViewController
        }
        
        set {
            setLeftViewController(newValue)
        }
    }
    
    var rightViewController: UIViewController?
    
    private var internalLeftViewControllerRevealed = true
    var isLeftViewControllerRevealed: Bool {
        get{
            return internalLeftViewControllerRevealed
        }
        
        set {
            internalLeftViewControllerRevealed = newValue
            
            updateLeftViewController(animated: true)
        }
    }
    
    weak var delegate: SplitViewControllerDelegate?

    //TODO private
    var leftView: UIView!
//    private
    var rightView: UIView!
    var openPercentage: CGFloat = 0 {
        didSet {
            updateRightAndLeftEdgeConstraints(openPercentage)
            
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    //TODO: private
    var leftViewLeadingConstraint: NSLayoutConstraint!
    var rightViewLeadingConstraint: NSLayoutConstraint!
    var leftViewWidthConstraint: NSLayoutConstraint!
    var rightViewWidthConstraint: NSLayoutConstraint!
    var sideBySideConstraint: NSLayoutConstraint!
    var pinLeftViewOffsetConstraint: NSLayoutConstraint!
    
    private var horizontalPanner: UIPanGestureRecognizer?
    private var futureTraitCollection: UITraitCollection?
    
    //MARK: - SplitLayoutObservable
    var layoutSize: SplitViewControllerLayoutSize = .compact {
        didSet {
            guard oldValue != layoutSize else { return }

            NotificationCenter.default.post(name: Notification.Name.SplitLayoutObservableDidChangeToLayoutSize, object: self)
        }
    }

    var leftViewControllerWidth: CGFloat {
        return leftViewWidthConstraint!.constant //TODO
    }

    //MARK: - init
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLeftViewControllerRevealed(_ leftViewControllerRevealed: Bool,
                                       animated: Bool,
                                       completion: Completion? = nil) {
        self.internalLeftViewControllerRevealed = leftViewControllerRevealed
        updateLeftViewController(animated: animated, completion: completion)
    }


    
    func setRightViewController(_ rightViewController: UIViewController?,
                                animated: Bool,
                                completion: Completion? = nil) {
        if self.rightViewController == rightViewController {
            return
        }
        
        // To determine if self.rightViewController.presentedViewController is actually presented over it, or is it
        // presented over one of it's parents.
        if self.rightViewController?.presentedViewController?.presentingViewController == self.rightViewController {
            self.rightViewController?.dismiss(animated: false)
        }
        
        let removedViewController = self.rightViewController
        
        let transitionDidStart = transition(from: removedViewController, to: rightViewController, containerView: rightView, animator: animatorForRightView, animated: animated, completion: completion)
        
        if transitionDidStart {
            self.rightViewController = rightViewController
        }
    }

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        leftView = UIView(frame: UIScreen.main.bounds)
        leftView?.translatesAutoresizingMaskIntoConstraints = false
        if let leftView = leftView {
            view.addSubview(leftView)
        }

        rightView = PlaceholderConversationView(frame: UIScreen.main.bounds)
        rightView?.translatesAutoresizingMaskIntoConstraints = false
        rightView?.backgroundColor = UIColor.from(scheme: .background)
        if let rightView = rightView {
            view.addSubview(rightView)
        }

        setupInitialConstraints()
        updateLayoutSize(for: traitCollection)
        updateConstraints(for: view.bounds.size)
        updateActiveConstraints()

        ///TODO: no side effect
//        setInternalLeftViewControllerRevealed(true)
//        self.internalLeftViewControllerRevealed = true
        openPercentage = 1
        horizontalPanner = UIPanGestureRecognizer(target: self, action: #selector(onHorizontalPan(_:)))
        horizontalPanner?.delegate = self
        view.addGestureRecognizer(horizontalPanner!)
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

        coordinator.animate(alongsideTransition: { context in
        }) { context in
            self.updateLayoutSizeAndLeftViewVisibility()
        }

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

    func setLeftViewController(_ leftViewController: UIViewController?,
                               animated: Bool = false,
                               transition: SplitViewControllerTransition = .`default`,
                               completion: Completion? = nil) {
        guard self.leftViewController != leftViewController else {
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

        if self.transition(from: removedViewController,
                           to: leftViewController,
                           containerView: leftView,
                           animator: animator,
                           animated: animated,
                           completion: completion) {
            self.internalLeftViewController = leftViewController
        }
    }

    //TODO private

    func update(for size: CGSize) {
        updateLayoutSize(for: futureTraitCollection ?? traitCollection)

        updateConstraints(for: size)
        updateActiveConstraints()

        futureTraitCollection = nil

        // update right view constraits after size changes
        updateRightAndLeftEdgeConstraints(openPercentage)
    }

    func updateLayoutSizeAndLeftViewVisibility() {
        updateLayoutSize(for: traitCollection)
        updateLeftViewVisibility()
    }

    func updateLeftViewVisibility() {
        switch layoutSize {
        case .compact /* fallthrough */, .regularPortrait:
            leftView.isHidden = (openPercentage == 0)
        case .regularLandscape:
            leftView.isHidden = false
        }
    }

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

        ///TODO: non optional
        let transitionContext = SplitViewControllerTransitionContext(from: fromViewController, to: toViewController, containerView: containerView)

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

    func resetOpenPercentage() {
        openPercentage = isLeftViewControllerRevealed ? 1 : 0
    }

    func updateRightAndLeftEdgeConstraints(_ percentage: CGFloat) {
        rightViewLeadingConstraint.constant = leftViewWidthConstraint.constant * percentage
        leftViewLeadingConstraint.constant = 64 * (1 - percentage)
    }
    //TODO end of private

}

extension UIViewController {
    var wr_splitViewController: SplitViewController? {
        var possibleSplit: UIViewController? = self

        repeat {
            if let splitViewController = possibleSplit as? SplitViewController {
                return splitViewController
            }

            possibleSplit = possibleSplit?.parent
        } while possibleSplit != nil

        return nil
    }
}
