//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

/// Replicates the launch screen to prevent the black screen being visible, cause of later UI initialization
class LaunchImageViewController: UIViewController {

    private var shouldShowLoadingScreenOnViewDidLoad = false

    private var contentView: UIView!
    private let loadingScreenLabel = UILabel()
    private let activityIndicator = ProgressSpinner()

    /// Convenience method for showing the @c activityIndicator and @c loadingScreenLabel and start the spinning animation
    func showLoadingScreen() {
        shouldShowLoadingScreenOnViewDidLoad = true
        loadingScreenLabel.isHidden = false
        activityIndicator.startAnimation()
    }

    /// Convenience method for hiding all the animation related functionality
    func hideLoadingScreen() {
        activityIndicator.stopAnimation()
        loadingScreenLabel.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let loadedObjects = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil)

        let nibView = loadedObjects.first as? UIView
        nibView?.translatesAutoresizingMaskIntoConstraints = false
        if let nibView = nibView {
            view.addSubview(nibView)
        }
        if let nibView = nibView {
            contentView = nibView
        }

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        loadingScreenLabel.font = .systemFont(ofSize: 12)
        loadingScreenLabel.textColor = .white

        loadingScreenLabel.text = "migration.please_wait_message".localized.uppercased(with: NSLocale.current)
        loadingScreenLabel.isHidden = true

        view.addSubview(loadingScreenLabel)

        createConstraints()

        // Start the spinner in case of it was requested right after the init
        if shouldShowLoadingScreenOnViewDidLoad {
            showLoadingScreen()
        }
    }

    private func createConstraints() {
        [contentView, loadingScreenLabel, activityIndicator].prepareForLayout()

        var constraints: [NSLayoutConstraint] = []

        constraints += [contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                        contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        contentView.topAnchor.constraint(equalTo: view.topAnchor),
                        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]

        constraints.append(loadingScreenLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(loadingScreenLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40))

        constraints.append(activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(activityIndicator.bottomAnchor.constraint(equalTo: loadingScreenLabel.topAnchor, constant: -24))

        NSLayoutConstraint.activate(constraints)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }
}
