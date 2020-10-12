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

// MARK: - NavigatorProtocol

public typealias NavigateBackClosure = () -> Void

public protocol NavigatorProtocol {
    var navigationController: UINavigationController { get }

    func push(_ viewController: UIViewController, animated: Bool, onNavigateBack: NavigateBackClosure?)
    func pop(_ animated: Bool)
    func present(_ viewController: UIViewController, animated: Bool, onComplete: (() -> Void)?)
    func setRoot(_ viewController: UIViewController, animated: Bool)
    func dismiss(_ viewController: UIViewController, animated: Bool)

    func addNavigateBack(closure: @escaping NavigateBackClosure, for viewController: UIViewController)
}

public extension NavigatorProtocol {
    func push(_ viewController: UIViewController) {
        push(viewController, animated: true, onNavigateBack: nil)
    }

    func push(_ viewController: UIViewController, animated: Bool) {
        push(viewController, animated: animated, onNavigateBack: nil)
    }

    func present(_ viewController: UIViewController) {
        present(viewController, animated: true, onComplete: nil)
    }

    func setRoot(_ viewController: UIViewController) {
        setRoot(viewController, animated: true)
    }
}

public class Navigator: NSObject, NavigatorProtocol {
    public let navigationController: UINavigationController
    private var closures: [UIViewController: NavigateBackClosure] = [:]

    public init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        navigationController.delegate = self
    }

    public func push(_ viewController: UIViewController,
                     animated: Bool,
                     onNavigateBack: NavigateBackClosure? = nil) {
        if let closure = onNavigateBack {
            addNavigateBack(closure: closure, for: viewController)
        }
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func pop(_ animated: Bool) {
        let vc = navigationController.popViewController(animated: animated)
        vc.flatMap { runCompletion(for: $0) }
    }

    public func dismiss(_ viewController: UIViewController, animated: Bool) {
        viewController.dismiss(animated: animated, completion: { [weak self] in
            self?.runCompletion(for: viewController)
        })
    }

    public func present(_ viewController: UIViewController,
                        animated: Bool,
                        onComplete: (() -> Void)?) {
        navigationController.present(viewController, animated: animated, completion: onComplete)
    }

    public func setRoot(_ viewController: UIViewController, animated: Bool) {
        closures.forEach { $0.value() }
        closures = [:]
        navigationController.viewControllers = [viewController]
    }

    public func addNavigateBack(closure: @escaping NavigateBackClosure,
                                for viewController: UIViewController) {
        print("adding closure for \(viewController)")
        closures.updateValue(closure, forKey: viewController)
    }

    private func runCompletion(for viewController: UIViewController) {
        guard let closure = closures.removeValue(forKey: viewController) else {
            return
        }
        print("adding closure for \(viewController)")
        closure()
    }
}

extension Navigator: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        guard
            let previousController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(previousController)
        else {
            return
        }
        runCompletion(for: previousController)
    }
}

// MARK: - NoBackTitleNavigationController

public final class NoBackTitleNavigationController: UINavigationController {
    public override var viewControllers: [UIViewController] {
        didSet {
            viewControllers.forEach(hideBackButton(for:))
        }
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        hideBackButton(for: viewController)
    }

    public override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        viewControllers.forEach(hideBackButton(for:))
    }
    
    private func hideBackButton(for viewController: UIViewController) {
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                                          style: .plain,
                                                                          target: nil,
                                                                          action: nil)
    }
}
