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

protocol CallInfoViewControllerDelegate: class {
    func infoViewController(_ viewController: CallInfoViewController, perform action: CallAction)
}

protocol CallInfoViewControllerInput: CallActionsViewInputType, CallStatusViewInputType  {
    var accessoryType: CallInfoViewControllerAccessoryType { get }
    var degradationState: CallDegradationState { get }
    var videoPlaceholderState: CallVideoPlaceholderState { get }
}

final class CallInfoViewController: UIViewController, CallActionsViewDelegate, CallAccessoryViewControllerDelegate {
    
    weak var delegate: CallInfoViewControllerDelegate?

    private let stackView = UIStackView(axis: .vertical)
    private let statusViewController: CallStatusViewController
    private let accessoryViewController: CallAccessoryViewController
    private let actionsView = CallActionsView()

    private let backgroundViewController: BackgroundViewController
    private let videoPlaceholderStatusLabel = UILabel()

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
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
    }

    private func setupViews() {
        addToSelf(backgroundViewController)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 40

        videoPlaceholderStatusLabel.text = "video_call.camera_access.denied".localized
        videoPlaceholderStatusLabel.textColor = .white
        videoPlaceholderStatusLabel.font = FontSpec(.normal, .semibold).font
        videoPlaceholderStatusLabel.alpha = 0.64
        videoPlaceholderStatusLabel.textAlignment = .center

        videoPlaceholderStatusLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        videoPlaceholderStatusLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)

        addChildViewController(statusViewController)
        [statusViewController.view, accessoryViewController.view, videoPlaceholderStatusLabel, actionsView].forEach(stackView.addArrangedSubview)
        statusViewController.didMove(toParentViewController: self)
    }

    private func createConstraints() {

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuideOrFallback.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuideOrFallback.bottomAnchor, constant: -40),
            actionsView.widthAnchor.constraint(equalToConstant: 288),
            actionsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 173),
            actionsView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            actionsView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            accessoryViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            videoPlaceholderStatusLabel.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        backgroundViewController.view.fitInSuperview()

    }
    
    private func updateNavigationItem() {
     navigationItem.leftBarButtonItem = UIBarButtonItem(
        icon: .downArrow,
        target: self,
        action: #selector(minimizeCallOverlay)
        )
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "CallDismissOverlayButton"
    }

    private func updateVideoPlaceholder() {

        switch configuration.videoPlaceholderState {
        case .hidden:
            backgroundViewController.view.isHidden = true
            videoPlaceholderStatusLabel.isHidden = true

        case .statusTextDisplayed:
            backgroundViewController.view.isHidden = false
            videoPlaceholderStatusLabel.isHidden = false

        case .statusTextHidden:
            backgroundViewController.view.isHidden = false
            videoPlaceholderStatusLabel.isHidden = true
        }

    }

    private func updateState() {
        Calling.log.debug("updating info controller with state: \(configuration)")
        actionsView.update(with: configuration)
        statusViewController.configuration = configuration
        accessoryViewController.configuration = configuration
        updateVideoPlaceholder()
    }
    
    // MARK: - Actions + Delegates
    
    func minimizeCallOverlay(_ sender: UIBarButtonItem) {
        delegate?.infoViewController(self, perform: .minimizeOverlay)
    }

    func callActionsView(_ callActionsView: CallActionsView, perform action: CallAction) {
        delegate?.infoViewController(self, perform: action)
    }
    
    func callAccessoryViewControllerDidSelectShowMore(viewController: CallAccessoryViewController) {
        delegate?.infoViewController(self, perform: .showParticipantsList)
    }

}
