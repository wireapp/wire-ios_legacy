//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class BottomSheetContainerViewController: UIViewController {

    // MARK: - Configuration
    public struct BottomSheetConfiguration: Equatable {
        let height: CGFloat
        let initialOffset: CGFloat
    }

    // MARK: - State
    public enum BottomSheetState {
        case initial
        case full
    }

    // MARK: - Variables
    private var topConstraint = NSLayoutConstraint()
    var state: BottomSheetState = .initial {
        didSet {
            didChangeState()
        }
    }
    private var visibleControllerBottomConstraint: NSLayoutConstraint!
    private var bottomViewHeightConstraint: NSLayoutConstraint!

    private(set) var contentViewController: UIViewController
    private(set) var bottomSheetViewController: UIViewController

    var configuration: BottomSheetConfiguration {
        didSet {
            visibleControllerBottomConstraint.constant = -configuration.initialOffset
            bottomViewHeightConstraint.constant = configuration.height
            view.setNeedsLayout()
        }
    }

    lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        pan.addTarget(self, action: #selector(handlePan))
        return pan
    }()

    // MARK: - Initialization
    public init(contentViewController: UIViewController,
                bottomSheetViewController: UIViewController,
                bottomSheetConfiguration: BottomSheetConfiguration) {

        self.contentViewController = contentViewController
        self.bottomSheetViewController = bottomSheetViewController
        self.configuration = bottomSheetConfiguration

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        addContentViewController(contentViewController: contentViewController)
        addBottomSheetViewController(bottomSheetViewController: bottomSheetViewController)
    }

    private func addBottomSheetViewController(bottomSheetViewController: UIViewController) {
        self.addChild(bottomSheetViewController)
        self.view.addSubview(bottomSheetViewController.view)

        bottomSheetViewController.view.addGestureRecognizer(panGesture)
        bottomSheetViewController.view.translatesAutoresizingMaskIntoConstraints = false

        topConstraint = bottomSheetViewController.view.topAnchor
            .constraint(equalTo: self.view.bottomAnchor,
                        constant: -configuration.initialOffset)

        bottomViewHeightConstraint = bottomSheetViewController.view.heightAnchor
            .constraint(equalToConstant: configuration.height)
        NSLayoutConstraint.activate([
            bottomViewHeightConstraint,
            bottomSheetViewController.view.leftAnchor
                .constraint(equalTo: self.view.leftAnchor),
            bottomSheetViewController.view.rightAnchor
                .constraint(equalTo: self.view.rightAnchor),
            topConstraint
        ])
        bottomSheetViewController.didMove(toParent: self)
    }

    func addContentViewController(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        self.addChild(contentViewController)
        self.view.addSubview(contentViewController.view)
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        visibleControllerBottomConstraint = contentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -configuration.initialOffset)

        NSLayoutConstraint.activate([
            contentViewController.view.leftAnchor
                .constraint(equalTo: self.view.leftAnchor),
            contentViewController.view.rightAnchor
                .constraint(equalTo: self.view.rightAnchor),
            contentViewController.view.topAnchor
                .constraint(equalTo: self.view.topAnchor).withPriority(.defaultLow),
            visibleControllerBottomConstraint
        ])
        contentViewController.didMove(toParent: self)

    }

    public func didChangeState() {} // for overriding

    // MARK: - Bottom Sheet Actions
    public func showBottomSheet(animated: Bool = true) {
        self.topConstraint.constant = -configuration.height

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
                self.bottomSheetChangedOffset(fullHeightPercentage: 1.0)
            }, completion: { _ in
                self.state = .full
            })
        } else {
            self.view.layoutIfNeeded()
            self.state = .full
            self.bottomSheetChangedOffset(fullHeightPercentage: 1.0)
        }
    }

    public func hideBottomSheet(animated: Bool = true) {
        self.topConstraint.constant = -configuration.initialOffset

        if animated {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5,
                           options: [.curveEaseOut],
                           animations: {
                self.view.layoutIfNeeded()
                self.bottomSheetChangedOffset(fullHeightPercentage: 0.0)
            }, completion: { _ in
                self.state = .initial
            })
        } else {
            self.view.layoutIfNeeded()
            self.state = .initial
            self.bottomSheetChangedOffset(fullHeightPercentage: 0.0)
        }
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: bottomSheetViewController.view)
        let velocity = sender.velocity(in: bottomSheetViewController.view)

        let yTranslationMagnitude = translation.y.magnitude

        switch sender.state {
        case .began, .changed:
            if self.state == .full {
                guard translation.y > 0 else { return }
                topConstraint.constant = -(configuration.height - yTranslationMagnitude)
                self.view.layoutIfNeeded()
            } else {
                let newConstant = -(configuration.initialOffset + yTranslationMagnitude)
                guard translation.y < 0 else { return }
                guard newConstant.magnitude < configuration.height else {
                    self.showBottomSheet()
                    return
                }
                topConstraint.constant = newConstant
                self.view.layoutIfNeeded()
            }
            let percent = (-topConstraint.constant - configuration.initialOffset) / (configuration.height - configuration.initialOffset)
            bottomSheetChangedOffset(fullHeightPercentage: percent)
        case .ended:
            if self.state == .full {
                if velocity.y < 0 {
                    self.showBottomSheet()
                } else if yTranslationMagnitude >= configuration.height / 2 || velocity.y > 1000 {
                    self.hideBottomSheet()
                } else {
                    self.showBottomSheet()
                }
            } else {
                if yTranslationMagnitude >= configuration.height / 2 || velocity.y < -1000 {
                    self.showBottomSheet()
                } else {
                    self.hideBottomSheet()
                }
            }
        case .failed:
            if self.state == .full {
                self.showBottomSheet()
            } else {
                self.hideBottomSheet()
            }
        default: break
        }
    }

    func bottomSheetChangedOffset(fullHeightPercentage: CGFloat) {}
}

extension BottomSheetContainerViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let otherGestureView = otherGestureRecognizer.view as? UIScrollView,
           otherGestureView.contentOffset.y > 0.0 {
            return false
        }
        return true
    }

}

extension BottomSheetContainerViewController: BottomSheetScrollingDelegate {
    var isBottomSheetExpanded: Bool {
        return state == .full
    }

    func toggleBottomSheetVisibility() {
        switch state {
        case .full:
            hideBottomSheet(animated: false)
        case .initial:
            showBottomSheet(animated: false)
        }
    }
}
