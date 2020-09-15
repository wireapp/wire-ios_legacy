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

import Foundation
import UIKit
import WireSyncEngine

protocol CallInfoViewControllerDelegate: class {
    func infoViewController(_ viewController: CallInfoViewController, perform action: CallAction)
}

protocol CallInfoViewControllerInput: CallActionsViewInputType, CallStatusViewInputType {
    var accessoryType: CallInfoViewControllerAccessoryType { get }
    var degradationState: CallDegradationState { get }
    var videoPlaceholderState: CallVideoPlaceholderState { get }
    var disableIdleTimer: Bool { get }
    var isConferenceCall: Bool { get }
}

// Workaround to make the protocol equatable, it might be possible to conform CallInfoConfiguration
// to Equatable with Swift 4.1 and conditional conformances. Right now we would have to make
// the `CallInfoRootViewController` generic to work around the `Self` requirement of
// `Equatable` which we want to avoid.
extension CallInfoViewControllerInput {
    func isEqual(toConfiguration other: CallInfoViewControllerInput) -> Bool {
        return accessoryType == other.accessoryType &&
            degradationState == other.degradationState &&
            videoPlaceholderState == other.videoPlaceholderState &&
            permissions == other.permissions &&
            disableIdleTimer == other.disableIdleTimer &&
            canToggleMediaType == other.canToggleMediaType &&
            isMuted == other.isMuted &&
            isTerminating == other.isTerminating &&
            canAccept == other.canAccept &&
            mediaState == other.mediaState &&
            appearance == other.appearance &&
            isVideoCall == other.isVideoCall &&
            variant == other.variant &&
            state == other.state &&
            isConstantBitRate == other.isConstantBitRate &&
            title == other.title &&
            cameraType == other.cameraType &&
            networkQuality == other.networkQuality &&
            userEnabledCBR == other.userEnabledCBR &&
            isConferenceCall == other.isConferenceCall
    }
}

final class CallInfoViewController: UIViewController, CallActionsViewDelegate, CallAccessoryViewControllerDelegate, CallInfoTopViewDelegate {

    weak var delegate: CallInfoViewControllerDelegate?

    private let backgroundViewController: BackgroundViewController
    private let stackView = UIStackView(axis: .vertical)
    private let statusViewController: CallStatusViewController
    private let accessoryViewController: CallAccessoryViewController
    private let actionsView = CallActionsView()
    private let topView = CallInfoTopView()
    private let errorView = CallInfoErrorView()
    
    var configuration: CallInfoViewControllerInput {
        didSet {
            updateState()
        }
    }

    init(configuration: CallInfoViewControllerInput) {
        self.configuration = configuration
        statusViewController = CallStatusViewController(configuration: configuration)
        accessoryViewController = CallAccessoryViewController(configuration: configuration)
        backgroundViewController = BackgroundViewController(user: ZMUser.selfUser(), userSession: ZMUserSession.shared())
        super.init(nibName: nil, bundle: nil)
        accessoryViewController.delegate = self
        actionsView.delegate = self
        topView.delegate = self
        topView.variant = configuration.effectiveColorVariant
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
        setNavigationBar(hidden: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setNavigationBar(hidden: false)
    }
    
    private func setNavigationBar(hidden: Bool) {
        navigationController?.navigationBar.isHidden = hidden
    }
    
    private func setupViews() {
        addToSelf(backgroundViewController)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16

        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorView)
        errorView.hide()
        
        addChild(statusViewController)
        [statusViewController.view, accessoryViewController.view, actionsView].forEach(stackView.addArrangedSubview)
        statusViewController.didMove(toParent: self)
    }

    private func createConstraints() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let navBarHeight = navigationController?.navigationBar.frame.size.height ?? 44
        
        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: view.topAnchor, constant: statusBarHeight),
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topView.heightAnchor.constraint(equalToConstant: navBarHeight),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            errorView.topAnchor.constraint(equalTo: view.topAnchor, constant: statusBarHeight),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuideOrFallback.bottomAnchor, constant: -40),
            actionsView.widthAnchor.constraint(equalToConstant: 288),
            actionsView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            actionsView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            accessoryViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        backgroundViewController.view.fitInSuperview()
    }

    private func updateState() {
        Log.calling.debug("updating info controller with state: \(configuration)")
        actionsView.update(with: configuration)
        statusViewController.configuration = configuration
        accessoryViewController.configuration = configuration
        backgroundViewController.view.isHidden = configuration.videoPlaceholderState == .hidden
        topView.setBadge(hidden: !configuration.isConferenceCall)
        
        if configuration.networkQuality.isNormal {
            errorView.hide()
        } else {
            errorView.show(message: "conversation.status.poor_connection".localized(uppercased: true))
        }
    }

    // MARK: - Actions + Delegates

    func callActionsView(_ callActionsView: CallActionsView, perform action: CallAction) {
        delegate?.infoViewController(self, perform: action)
    }

    func callAccessoryViewControllerDidSelectShowMore(viewController: CallAccessoryViewController) {
        delegate?.infoViewController(self, perform: .showParticipantsList)
    }
    
    func callInfoTopViewDidAskToMinimizeOverlay(_ callInfoTopView: UIView) {
        delegate?.infoViewController(self, perform: .minimizeOverlay)
    }
}
