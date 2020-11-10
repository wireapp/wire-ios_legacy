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

typealias SpinnerCapableViewController = UIViewController & SpinnerCapable
typealias SpinnerCompletion = Completion

protocol SpinnerCapable: class {
    var dismissSpinner: SpinnerCompletion? { get set }
}

extension SpinnerCapable where Self: UIViewController {
    func showLoadingView(title: String) {
        dismissSpinner = presentSpinner(title: title)
    }

    var isLoadingViewVisible: Bool {
        set {
            if newValue {
                // do not show double spinners
                guard !isLoadingViewVisible else { return }

                dismissSpinner = presentSpinner()
            } else {
                dismissSpinner?()
                dismissSpinner = nil
            }
        }

        get {
            return dismissSpinner != nil
        }
    }

    private func presentSpinner(title: String? = nil) -> Completion {
        // Starts animating when it appears, stops when it disappears
        let spinnerView = createSpinner(title: title)
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinnerView)

        NSLayoutConstraint.activate([
            spinnerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spinnerView.topAnchor.constraint(equalTo: view.topAnchor),
            spinnerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spinnerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        UIAccessibility.post(notification: .announcement, argument: "general.loading".localized)
        spinnerView.spinnerSubtitleView.spinner.startAnimation()

        return {
            spinnerView.removeFromSuperview()
        }
    }

    fileprivate func createSpinner(title: String? = nil) -> LoadingSpinnerView {
        let loadingSpinnerView = LoadingSpinnerView()
        loadingSpinnerView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        loadingSpinnerView.spinnerSubtitleView.subtitle = title

        return loadingSpinnerView
    }

}

// MARK: - LoadingSpinnerView
final class LoadingSpinnerView: UIView {
    let spinnerSubtitleView: SpinnerSubtitleView = SpinnerSubtitleView()

    init() {
        super.init(frame: .zero)
        addSubview(spinnerSubtitleView)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        spinnerSubtitleView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            spinnerSubtitleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerSubtitleView.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
}

// MARK: - SpinnerCapableNavigationController
final class SpinnerCapableNavigationController: UINavigationController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
    
}

extension UINavigationController {
    var isLoadingViewVisible: Bool? {
        get {
            return (self as? SpinnerCapableViewController)?.isLoadingViewVisible
        }

        set {
            if let newValue = newValue {
                (self as? SpinnerCapableViewController)?.isLoadingViewVisible = newValue
            }
        }
    }
}
