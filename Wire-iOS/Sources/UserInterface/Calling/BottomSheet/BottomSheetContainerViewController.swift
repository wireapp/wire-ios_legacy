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

public struct BottomSheetConfiguration {

    let height: CGFloat
    let initialOffset: CGFloat

}

public enum BottomSheetState {

    case initial
    case full

}

class BottomSheetContainerViewController<Content: UIViewController, BottomSheet: UIViewController>: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Properties
    private let configuration: BottomSheetConfiguration
    private var topConstraint = NSLayoutConstraint()

    let contentViewController: Content
    let bottomSheetViewController: BottomSheet

    var state: BottomSheetState = .initial

    lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        pan.addTarget(self, action: #selector(handlePan))
        return pan
    }()

    // MARK: - Initialization

    init(contentViewController: Content,
         bottomSheetViewController: BottomSheet,
         bottomSheetConfiguration: BottomSheetConfiguration) {

        self.contentViewController = contentViewController
        self.bottomSheetViewController = bottomSheetViewController
        self.configuration = bottomSheetConfiguration

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createConstraints()
    }


    private func createConstraints() {
//          self.addChild(contentViewController)
          self.addChild(bottomSheetViewController)
//          self.view.addSubview(contentViewController.view)
          self.view.addSubview(bottomSheetViewController.view)

          bottomSheetViewController.view.addGestureRecognizer(panGesture)

          contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
          bottomSheetViewController.view.translatesAutoresizingMaskIntoConstraints = false

//        NSLayoutConstraint.activate([
//            contentViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
//            contentViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
//            contentViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
//            contentViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
//        ])

         // contentViewController.didMove(toParent: self)

          topConstraint = bottomSheetViewController.view.topAnchor
              .constraint(equalTo: self.view.bottomAnchor,
                          constant: -configuration.initialOffset)

          NSLayoutConstraint.activate([
              bottomSheetViewController.view.heightAnchor.constraint(equalToConstant: configuration.height),
              bottomSheetViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
              bottomSheetViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
              topConstraint
          ])

          bottomSheetViewController.didMove(toParent: self)
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

    // MARK: - UIGestureRecognizer Delegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

// MARK: - Bottom Sheet Actions

extension BottomSheetContainerViewController {

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

}

final class WelcomeContainerViewController: BottomSheetContainerViewController<HelloViewController, MyCustomViewController> {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do something
    }

}

class HelloViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .yellow//.lightGray
    }

}

class MyCustomViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .red//.white
        self.view.layer.cornerRadius = 20
        self.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.view.layer.shadowColor = UIColor.black.cgColor
        self.view.layer.shadowOffset = .init(width: 0, height: -2)
        self.view.layer.shadowRadius = 20
        self.view.layer.shadowOpacity = 0.5
    }
}
