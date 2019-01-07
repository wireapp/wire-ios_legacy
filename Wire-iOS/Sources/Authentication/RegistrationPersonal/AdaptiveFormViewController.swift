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

import UIKit

/**
 * A view controller that wraps an authentication view controller and adapts its presentation based on the device.
 */

class AdaptiveFormViewController: BlueViewController, AuthenticationCoordinatedViewController {

    let childViewController: AuthenticationStepViewController

    weak var authenticationCoordinator: AuthenticationCoordinator? {
        didSet {
            childViewController.authenticationCoordinator = authenticationCoordinator
        }
    }

    private var regularConstraints: [NSLayoutConstraint]?
    private var compactConstraints: [NSLayoutConstraint]?

    // MARK: - Initialization

    init(childViewController: AuthenticationStepViewController) {
        self.childViewController = childViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    // MARK: - Interface Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        configureChildren()
        configureConstraints()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return childViewController.preferredStatusBarStyle
    }

    override var canBecomeFirstResponder: Bool {
        return childViewController.canBecomeFirstResponder
    }

    override var canResignFirstResponder: Bool {
        return childViewController.canResignFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        return childViewController.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return childViewController.resignFirstResponder()
    }

    private func configureChildren() {
        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }

    private func configureConstraints() {
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false

        regularConstraints = [
            childViewController.view.widthAnchor.constraint(equalToConstant: maximumFormSize.width),
            childViewController.view.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor)
        ]

        compactConstraints = [
            childViewController.view.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            childViewController.view.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)
        ]

        NSLayoutConstraint.activate([
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        updateConstraints(usingRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

    // MARK: - Constraints

    /**
     * Updates the constraints of the app when the view controller size changes.
     */

    func updateConstraints(usingRegularLayout isRegular: Bool) {
        if isRegular {
            compactConstraints.apply(NSLayoutConstraint.deactivate)
            regularConstraints.apply(NSLayoutConstraint.activate)
        } else {
            regularConstraints.apply(NSLayoutConstraint.deactivate)
            compactConstraints.apply(NSLayoutConstraint.activate)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateConstraints(usingRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

    // MARK: - AuthenticationCoordinatedViewController

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        childViewController.executeErrorFeedbackAction?(feedbackAction)
    }

    func displayError(_ error: Error) {
        childViewController.displayError?(error)
    }

}
