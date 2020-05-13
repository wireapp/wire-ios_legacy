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

class PreBackendSwitchViewController: AuthenticationStepViewController {
    
    var authenticationCoordinator: AuthenticationCoordinator?
    var backendURL: URL?

    var delegate: PreBackendSwitchViewControllerDelegate? {
        return authenticationCoordinator
    }

    // MARK: - UI Styles
    
    static let informationBlue = UIColor(red: 35/255, green: 145/255, blue: 211/255, alpha: 1)
    static let informationBackgroundBlue = UIColor(red: 220/255, green: 237/255, blue: 248/255, alpha: 1)
    
    // MARK: - UI Elements
    
    let contentView = UIView()
    
    let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    let progressContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 40
        view.backgroundColor = UIColor(red: 50/255, green: 54/255, blue: 57/255, alpha: 1)
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 5
        view.layer.shadowOpacity = 0.29
        view.layer.shadowColor = UIColor.black.cgColor
        view.accessibilityIdentifier = "ProgressView"
        return view
    }()
    
    let wireLogo: UIImageView = {
        let logo = UIImageView(image: UIImage(named: "wire-logo-letter"))
        logo.accessibilityIdentifier = "ProgressView.Logo"
        return logo
    }()

    let progressView: TimedCircularProgressView = {
        let progress = TimedCircularProgressView()
        progress.lineWidth = 4
        progress.lineCap = .round
        progress.tintColor = PreBackendSwitchViewController.informationBlue
        progress.duration = 5
        progress.accessibilityIdentifier = "ProgressView.Timer"
        return progress
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec(.large, .semibold).font!
        label.textAlignment = .center
        label.text = "login.sso.backend_switch.title".localized
        label.accessibilityValue = label.text
        label.textColor = .black
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec(.normal, .regular).font!
        label.textAlignment = .center
        label.text = "login.sso.backend_switch.subtitle".localized
        label.accessibilityValue = label.text
        label.textColor = .black
        return label
    }()
    
    let backendUrlLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec(.normal, .semibold).font!
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    let informationView: UIView = {
        let view = UIView()
        view.backgroundColor = PreBackendSwitchViewController.informationBackgroundBlue
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    let informationIcon = UIImageView(image: UIImage.imageForIcon(.about, size: 16, color: PreBackendSwitchViewController.informationBlue))
    
    let informationLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec(.normal, .light).font!.withSize(14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = PreBackendSwitchViewController.informationBlue
        label.text = "login.sso.backend_switch.information".localized
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Team.background
        navigationController?.navigationBar.barStyle = .black
        
        configureSubviews()
        createConstraints()
        
        backendUrlLabel.text = backendURL?.absoluteString
        backendUrlLabel.accessibilityValue = backendUrlLabel.text
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
        view.addSubview(headerView)

        informationView.addSubview(informationIcon)
        informationView.addSubview(informationLabel)
        
        contentView.addSubview(progressContainerView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(backendUrlLabel)
        contentView.addSubview(informationView)
        
        progressContainerView.addSubview(progressView)
        progressContainerView.addSubview(wireLogo)

        view.addSubview(contentView)
    }
    
    private func createConstraints() {
        disableAutoresizingMaskTranslation(for: [
            headerView,
            contentView,
            progressContainerView,
            wireLogo,
            progressView,
            titleLabel,
            subtitleLabel,
            backendUrlLabel,
            informationView,
            informationIcon,
            informationLabel
        ])
        
        NSLayoutConstraint.activate([
            // header view
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: contentView.topAnchor),

            // content view
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // progress container view
            progressContainerView.centerYAnchor.constraint(equalTo: contentView.topAnchor),
            progressContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressContainerView.widthAnchor.constraint(equalToConstant: 80),
            progressContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            // wire logo
            wireLogo.centerYAnchor.constraint(equalTo: progressContainerView.centerYAnchor),
            wireLogo.centerXAnchor.constraint(equalTo: progressContainerView.centerXAnchor),
            
            // progress view
            progressView.centerXAnchor.constraint(equalTo: progressContainerView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: progressContainerView.centerYAnchor),
            progressView.widthAnchor.constraint(equalTo: progressContainerView.widthAnchor),
            progressView.heightAnchor.constraint(equalTo: progressContainerView.heightAnchor),

            // title label
            titleLabel.topAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // backend url label
            backendUrlLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor),
            backendUrlLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backendUrlLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // information view
            informationView.topAnchor.constraint(equalTo: backendUrlLabel.bottomAnchor, constant: 39),
            informationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            informationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            informationView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // information icon
            informationIcon.topAnchor.constraint(equalTo: informationView.topAnchor, constant: 16),
            informationIcon.centerXAnchor.constraint(equalTo: informationView.centerXAnchor),
            informationIcon.widthAnchor.constraint(equalToConstant: 16),
            informationIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // information label
            informationLabel.topAnchor.constraint(equalTo: informationIcon.bottomAnchor, constant: 7),
            informationLabel.leadingAnchor.constraint(equalTo: informationView.leadingAnchor, constant: 28),
            informationLabel.trailingAnchor.constraint(equalTo: informationView.trailingAnchor, constant: -28),
            informationLabel.bottomAnchor.constraint(equalTo: informationView.bottomAnchor, constant: -16)
        ])
    }

    private func disableAutoresizingMaskTranslation(for views: [UIView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // NO OP
    }
    
    func displayError(_ error: Error) {
        // NO OP
    }
}
