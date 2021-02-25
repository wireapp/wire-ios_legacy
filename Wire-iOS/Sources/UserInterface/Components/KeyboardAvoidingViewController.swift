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

import Foundation
import UIKit

class KeyboardAvoidingViewController: UIViewController, SpinnerCapable {

    //MARK: SpinnerCapable
    var dismissSpinner: SpinnerCompletion?

    let viewController: UIViewController
    var disabledWhenInsidePopover: Bool = false

    private var animator: UIViewPropertyAnimator?
    private var bottomEdgeConstraint: NSLayoutConstraint?
    private var topEdgeConstraint: NSLayoutConstraint?

    required init(viewController: UIViewController) {
        self.viewController = viewController

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameWillChange),
                                               name: UIWindow.keyboardWillChangeFrameNotification,
                                               object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var shouldAutorotate: Bool {
        return viewController.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return viewController.supportedInterfaceOrientations
    }

    override var navigationItem: UINavigationItem {
        return viewController.navigationItem
    }

    override var childForStatusBarStyle: UIViewController? {
        return viewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return viewController
    }

    override var title: String? {
        get {
            return viewController.title
        }
        set {
            viewController.title = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isOpaque = false
        addChild(viewController)
        view.addSubview(viewController.view)
        view.backgroundColor = viewController.view.backgroundColor
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.didMove(toParent: self)

        createInitialConstraints()
    }

    private func createInitialConstraints() {

        let constraints = viewController.view.fitInSuperview(exclude: [.bottom])

        topEdgeConstraint = constraints[.top]

        if #available(iOS 11.0, *) {
            bottomEdgeConstraint = viewController.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        } else {
            bottomEdgeConstraint = viewController.bottomLayoutGuide.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor, constant: 0)
        }

        bottomEdgeConstraint?.isActive = true
    }

    @objc
    private func keyboardFrameWillChange(_ notification: Notification?) {
        guard let bottomEdgeConstraint = bottomEdgeConstraint else { return }

        guard !disabledWhenInsidePopover || !isInsidePopover else {
            bottomEdgeConstraint.constant = 0
            view.layoutIfNeeded()
            return
        }

        guard let userInfo = notification?.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }

        let keyboardFrameInView = UIView.keyboardFrame(in: self.view, forKeyboardNotification: notification)
        var bottomOffset: CGFloat

        if #available(iOS 11.0, *) {
            // The keyboard frame includes the safe area so we need to substract it since the bottomEdgeConstraint is attached to the safe area.
            bottomOffset = -keyboardFrameInView.intersection(view.safeAreaLayoutGuide.layoutFrame).height
        } else {
            bottomOffset = -abs(keyboardFrameInView.size.height)
        }

        // When the keyboard is visible &
        // this controller's view is presented at a form sheet style on iPad, the view is has a top offset and the bottomOffset should be reduced.
        if !keyboardFrameInView.origin.y.isInfinite,
            modalPresentationStyle == .formSheet,
            let frame = presentationController?.frameOfPresentedViewInContainerView {
            bottomOffset += frame.minY ///TODO: no need to add when no keyboard
        }

        guard bottomEdgeConstraint.constant != bottomOffset else { return }

        // When the keyboard is dismissed and then quickly revealed again, then
        // the dismiss animation will be cancelled.
        animator?.stopAnimation(true)
        view.layoutIfNeeded()

        animator = UIViewPropertyAnimator(duration: duration, timingParameters: UISpringTimingParameters())

        animator?.addAnimations {
            bottomEdgeConstraint.constant = bottomOffset
            self.view.layoutIfNeeded()
        }

        animator?.addCompletion { [weak self] _ in
            self?.animator = nil
        }

        animator?.startAnimation()
    }

}
