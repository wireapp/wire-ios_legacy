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


// The ouput actions a `CallInfoViewController` can perform.
enum CallAction {
    case toggleMuteState
    case toggleVideoState
    case toggleSpeakerState
    case acceptCall
    case terminateCall
    case flipCamera
    case showParticipantsList
    
    static func action(for action: CallActionsViewAction) -> CallAction {
        switch action {
        case .toggleMuteState: return .toggleMuteState
        case .toggleVideoState: return .toggleVideoState
        case .toggleSpeakerState: return .toggleSpeakerState
        case .acceptCall: return .acceptCall
        case .terminateCall: return .terminateCall
        case .flipCamera: return .flipCamera
        }
    }
}

protocol CallInfoViewControllerDelegate: class {
    func infoViewController(_ viewController: CallInfoViewController, perform action: CallAction)
}


enum CallInfoViewControllerAccessoryType: CallParticipantsViewModel {
    case avatar(ZMUser)
    case participantsList(CallParticipantsViewModel)
    
    var showAvater: Bool {
        guard case .avatar = self else { return false}
        return true
    }
    
    var rows: [CallParticipantsCellConfiguration] {
        switch self {
        case .avatar: return []
        case .participantsList(let model): return model.rows
        }
    }
}

protocol CallInfoViewControllerInput: CallActionsViewInputType, CallStatusViewInputType  {
    var accessoryType: CallInfoViewControllerAccessoryType { get }
    
}

final class CallInfoViewController: UIViewController, CallActionsViewDelegate {
    
    weak var delegate: CallInfoViewControllerDelegate?
    
    private let actionsView = CallActionsView()
    private let statusViewController: CallStatusViewController
    private let participantsViewController: CallParticipantsViewController
    private let avatarView = UserImageView(size: .big)
    
    var configuration: CallInfoViewControllerInput {
        didSet {
            updateState()
        }
    }
    
    fileprivate var isSwitchingCamera = false
    fileprivate var currentCaptureDevice: CaptureDevice = .front

    var variant: ColorSchemeVariant = .dark
    
    init(configuration: CallInfoViewControllerInput) {
        self.configuration = configuration
        statusViewController = CallStatusViewController(configuration: configuration)
        participantsViewController = CallParticipantsViewController(viewModel: configuration.accessoryType, allowsScrolling: false)
        super.init(nibName: nil, bundle: nil)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
    }

    private func setupViews() {
        add(statusViewController, to: view)
        view.addSubview(actionsView)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            statusViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            statusViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionsView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            actionsView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            actionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            actionsView.heightAnchor.constraint(lessThanOrEqualToConstant: 213),
            actionsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 213)
        ])
    }

    private func updateState() {
//        actionsView.update(with: configuration.callActionsViewInput)
//        statusViewController.configuration = configuration.statusViewConfiguration
        
        avatarView.isHidden = !configuration.accessoryType.showAvater
        participantsViewController.view.isHidden = configuration.accessoryType.showAvater
        participantsViewController.viewModel = configuration.accessoryType
    }

    func callActionsView(_ callActionsView: CallActionsView, perform action: CallActionsViewAction) {
        Calling.log.debug("\(action) button tapped")
        delegate?.infoViewController(self, perform: CallAction.action(for: action))
    }
}
