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
import WireCommonComponents

protocol PreBackendSwitchViewControllerDelegate {
    func preBackendSwitchViewControllerDidComplete(_ url: URL)
}

final class PreBackendSwitchViewController: AuthenticationStepViewController {

    var authenticationCoordinator: AuthenticationCoordinator?
    var backendURL: URL?

    var delegate: PreBackendSwitchViewControllerDelegate? {
        return authenticationCoordinator
    }

    // MARK: - UI Styles

    static let informationBlue = UIColor(red: 35/255, green: 145/255, blue: 211/255, alpha: 1)
    static let informationBackgroundBlue = UIColor(red: 220/255, green: 237/255, blue: 248/255, alpha: 1)

    // MARK: - UI Elements
    let wireLogoInfoView = WireLogoInfoView(title: "login.sso.backend_switch.title".localized, subtitle: "login.sso.backend_switch.subtitle".localized)

    let progressView: TimedCircularProgressView = {
        let progress = TimedCircularProgressView()
        progress.lineWidth = 4
        progress.lineCap = .round
        progress.tintColor = PreBackendSwitchViewController.informationBlue
        progress.duration = 5
        progress.accessibilityIdentifier = "ProgressView.Timer"
        return progress
    }()

    let informationLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec(.normal, .semibold).font!
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .black
        label.text = "login.sso.backend_switch.information".localized
        label.accessibilityValue = label.text
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Team.background
        navigationController?.navigationBar.barStyle = .black

        configureSubviews()
        createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressView.animate { [backendURL, delegate] in
            guard let url = backendURL else {
                return
            }
            delegate?.preBackendSwitchViewControllerDidComplete(url)
        }
    }

    private func configureSubviews() {
        view.addSubview(wireLogoInfoView)

        wireLogoInfoView.contentView.addSubview(informationLabel)

        wireLogoInfoView.progressContainerView.addSubview(progressView)
    }

    private func createConstraints() {
        [wireLogoInfoView,
         progressView,
         informationLabel].disableAutoresizingMaskTranslation()

        NSLayoutConstraint.activate([
            wireLogoInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wireLogoInfoView.topAnchor.constraint(equalTo: view.topAnchor),
            wireLogoInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wireLogoInfoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // progress view
            progressView.centerXAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.centerYAnchor),
            progressView.widthAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.widthAnchor),
            progressView.heightAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.heightAnchor),

            // information label
            informationLabel.topAnchor.constraint(equalTo: wireLogoInfoView.subtitleLabel.bottomAnchor, constant: 10),
            informationLabel.leadingAnchor.constraint(equalTo: wireLogoInfoView.contentView.leadingAnchor),
            informationLabel.trailingAnchor.constraint(equalTo: wireLogoInfoView.contentView.trailingAnchor)])
    }

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // NO OP
    }

    func displayError(_ error: Error) {
        // NO OP
    }
}
