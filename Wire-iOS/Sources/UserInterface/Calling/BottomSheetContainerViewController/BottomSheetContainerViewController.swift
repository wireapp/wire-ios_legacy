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

class BottomSheetContainerViewController : UIViewController {

    // MARK: - Configuration
    public struct BottomSheetConfiguration {
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
    private let configuration: BottomSheetConfiguration
    var state: BottomSheetState = .initial

    let contentViewController: UIViewController
    let bottomSheetViewController: UIViewController

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

    private func setupUI() {
        // 1
        self.addChild(contentViewController)
        self.addChild(bottomSheetViewController)

        // 2
        self.view.addSubview(contentViewController.view)
        self.view.addSubview(bottomSheetViewController.view)

        // 3
        bottomSheetViewController.view.addGestureRecognizer(panGesture)

        // 4
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetViewController.view.translatesAutoresizingMaskIntoConstraints = false

        // 5
        NSLayoutConstraint.activate([
            contentViewController.view.leftAnchor
                .constraint(equalTo: self.view.leftAnchor),
            contentViewController.view.rightAnchor
                .constraint(equalTo: self.view.rightAnchor),
            contentViewController.view.topAnchor
                .constraint(equalTo: self.view.topAnchor),
            contentViewController.view.bottomAnchor
                .constraint(equalTo: self.view.bottomAnchor)
        ])

        // 6
        contentViewController.didMove(toParent: self)

        // 7
        topConstraint = bottomSheetViewController.view.topAnchor
            .constraint(equalTo: self.view.bottomAnchor,
                        constant: -configuration.initialOffset)

        // 8
        NSLayoutConstraint.activate([
            bottomSheetViewController.view.heightAnchor
                .constraint(equalToConstant: configuration.height),
            bottomSheetViewController.view.leftAnchor
                .constraint(equalTo: self.view.leftAnchor),
            bottomSheetViewController.view.rightAnchor
                .constraint(equalTo: self.view.rightAnchor),
            topConstraint
        ])
        // 9
        bottomSheetViewController.didMove(toParent: self)
    }

    // MARK: - Bottom Sheet Actions
    public func showBottomSheet(animated: Bool = true) {
        self.topConstraint.constant = -configuration.height

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.state = .full
            })
        } else {
            self.view.layoutIfNeeded()
            self.state = .full
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
            }, completion: { _ in
                self.state = .initial
            })
        } else {
            self.view.layoutIfNeeded()
            self.state = .initial
        }
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: bottomSheetViewController.view)
        let velocity = sender.velocity(in: bottomSheetViewController.view)

        let yTranslationMagnitude = translation.y.magnitude

        switch sender.state {
        case .began, .changed:
            if self.state == .full {
                // 1
                guard translation.y > 0 else { return }

                // 2
                topConstraint.constant = -(configuration.height - yTranslationMagnitude)

                // 3
                self.view.layoutIfNeeded()
            } else {
                // 4
                let newConstant = -(configuration.initialOffset + yTranslationMagnitude)

                // 5
                guard translation.y < 0 else { return }

                // 6
                guard newConstant.magnitude < configuration.height else {
                    self.showBottomSheet()
                    return
                }

                // 7
                topConstraint.constant = newConstant

                // 8
                self.view.layoutIfNeeded()
            }
        case .ended:
            if self.state == .full {
                // 1
                if velocity.y < 0 {
                    self.showBottomSheet()
                } else if yTranslationMagnitude >= configuration.height / 2 || velocity.y > 1000 {
                    // 2
                    self.hideBottomSheet()
                } else {
                    // 3
                    self.showBottomSheet()
                }
            } else {
                // 4
                if yTranslationMagnitude >= configuration.height / 2 || velocity.y < -1000 {
                    // 5
                    self.showBottomSheet()
                } else {
                    // 6
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

}

extension BottomSheetContainerViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
