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

final class RootViewController: UIViewController {
    // MARK: - SpinnerCapable
    var dismissSpinner: SpinnerCompletion?

    // MARK: - PopoverPresenter
    var presentedPopover: UIPopoverPresentationController?
    var popoverPointToView: UIView?

    // MARK: - Public Property
    var isPresenting: Bool {
        return presentedViewController != nil
    }

    // MARK: - Private Property
    private var childViewController: UIViewController?

    // MARK: - Status Bar / Supported Orientations

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let viewController = presentedViewController,
           viewController is ModalPresentationViewController,
           !viewController.isBeingDismissed {
            return viewController.supportedInterfaceOrientations
        }
        return wr_supportedInterfaceOrientations
    }

    override var childForStatusBarStyle: UIViewController? {
        return childViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return childViewController
    }

    func set(childViewController newViewController: UIViewController?,
             animated: Bool = false,
             completion: (() -> Void)? = nil) {
        if let newViewController = newViewController,
            let previousViewController = childViewController {
            transition(
                from: previousViewController,
                to: newViewController,
                animated: animated,
                completion: completion)
        } else if let newViewController = newViewController {
            contain(newViewController, completion: completion)
        } else {
            removeChildViewController(animated: animated, completion: completion)
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    private func contain(_ newViewController: UIViewController, completion: (() -> Void)?) {
        UIView.performWithoutAnimation {
            add(newViewController, to: view)
            childViewController = newViewController
            completion?()
        }
    }

    private func removeChildViewController(animated: Bool, completion: (() -> Void)?) {
        let animationGroup = DispatchGroup()
        if childViewController?.presentedViewController != nil {
            animationGroup.enter()
            childViewController?.dismiss(animated: animated) {
                animationGroup.leave()
            }
        }

        childViewController?.willMove(toParent: nil)
        childViewController?.view.removeFromSuperview()
        childViewController?.removeFromParent()
        childViewController = nil

        animationGroup.notify(queue: .main) {
            completion?()
        }
    }

    private func transition(from fromViewController: UIViewController,
                            to toViewController: UIViewController,
                            animated: Bool = false,
                            completion: (() -> Void)?) {
        let animationGroup = DispatchGroup()

        if fromViewController.presentedViewController != nil {
            animationGroup.enter()
            fromViewController.dismiss(animated: animated) {
                animationGroup.leave()
            }
        }

        fromViewController.willMove(toParent: nil)
        addChild(toViewController)

        toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toViewController.view.frame = fromViewController.view.bounds

        animationGroup.enter()
        transition(
            from: fromViewController,
            to: toViewController,
            duration: 0.5,
            options: .transitionCrossDissolve,
            animations: {
                self.view.bringSubviewToFront(fromViewController.view)
                fromViewController.view.alpha = 0
            }, completion: { _ in
                fromViewController.removeFromParent()
                toViewController.didMove(toParent: self)
                animationGroup.leave()
            })

        childViewController = toViewController

        animationGroup.notify(queue: .main) {
            completion?()
        }
    }
}

extension RootViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let appRouter = (UIApplication.shared.delegate as? AppDelegate)?.appRootRouter else {
            return
        }

        coordinator.animate(alongsideTransition: nil, completion: { _ in
            appRouter.updateOverlayWindowFrame(size: size)
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Do not refresh for iOS 13+ when the app is in background.
        // Go to home screen may trigger `traitCollectionDidChange` twice.
        if #available(iOS 13.0, *) {
            if UIApplication.shared.applicationState == .background {
                return
            }
        }

        if #available(iOS 12.0, *) {
            if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
                NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: nil)
            }
        }
    }
}

extension RootViewController: SpinnerCapable { }
extension RootViewController: PopoverPresenter { }
