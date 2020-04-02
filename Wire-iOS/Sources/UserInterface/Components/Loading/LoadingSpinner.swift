
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
            spinnerSubtitleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
    }
}

protocol LoadingSpinner: class {
    var loadingSpinnerView: LoadingSpinnerView { get }
    var showSpinner: Bool { get set }
    var spinnerSubtitle: String? { get set }
}

extension UIViewController {
    func createLoadingSpinnerView() -> LoadingSpinnerView {
        let loadingSpinnerView = LoadingSpinnerView()
        loadingSpinnerView.isHidden = true
        loadingSpinnerView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        
        
        return loadingSpinnerView
    }
    
    var showSpinner: Bool {
        get {
            return false
        }
        
        set {
            if newValue {
                let loadingSpinnerView = createLoadingSpinnerView()
                
                let viewController = UIViewController()
                viewController.view.backgroundColor = .clear
                viewController.view.addSubview(loadingSpinnerView)

//                viewController.view = loadingSpinnerView
                loadingSpinnerView.isHidden = false
                
                viewController.createConstraints(container: loadingSpinnerView)

                addToSelf(viewController)
//                loadingSpinnerView.layoutIfNeeded()
//                viewController.view.layoutIfNeeded()
                UIAccessibility.post(notification: .announcement, argument: "general.loading".localized)
                loadingSpinnerView.spinnerSubtitleView.spinner.startAnimation()
            } else {
                ///TODO: dismiss/hide
            }
        }
    }
    
    private func createConstraints(container: UIView) {
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
    }

}

extension LoadingSpinner where Self: UIViewController {
    
    var spinnerSubtitle: String? {
        get {
            return loadingSpinnerView.spinnerSubtitleView.subtitle
        }
        
        set {
            loadingSpinnerView.spinnerSubtitleView.subtitle = newValue
        }
    }

    var showSpinner: Bool {
        get {
            return !loadingSpinnerView.isHidden
        }
        
        set(shouldShow) {
            loadingSpinnerView.isHidden = !shouldShow
            view.isUserInteractionEnabled = !shouldShow
            
            if shouldShow {
                UIAccessibility.post(notification: .announcement, argument: "general.loading".localized)
                loadingSpinnerView.spinnerSubtitleView.spinner.startAnimation()
            } else {
                loadingSpinnerView.spinnerSubtitleView.spinner.stopAnimation()
            }
        }
    }

}
