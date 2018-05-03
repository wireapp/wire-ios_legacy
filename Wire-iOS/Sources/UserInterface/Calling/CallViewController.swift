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
    
    var showAvatar: Bool {
        return nil != user
    }
    
    var user: ZMUser? {
        guard case .avatar(let user) = self else { return nil }
        return user
    }
    
    var rows: [CallParticipantsCellConfiguration] {
        switch self {
        case .avatar: return []
        case .participantsList(let model): return model.rows
        }
    }
}

final class UserImageViewContainer: UIView {
    private let userImageView: UserImageView
    private let maxSize: CGFloat
    private let yOffset: CGFloat
    
    var user: ZMBareUser? {
        didSet {
            userImageView.user = user
        }
    }
    
    init(size: UserImageViewSize, maxSize: CGFloat, yOffset: CGFloat) {
        userImageView = UserImageView(size: size)
        self.maxSize = maxSize
        self.yOffset = yOffset
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userImageView)
        userImageView.setContentHuggingPriority(249, for: .vertical)
        userImageView.setContentHuggingPriority(249, for: .horizontal)
        userImageView.setContentCompressionResistancePriority(249, for: .vertical)
        userImageView.setContentCompressionResistancePriority(249, for: .horizontal)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: yOffset),
            userImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            userImageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            userImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            userImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            userImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            userImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxSize),
            userImageView.heightAnchor.constraint(lessThanOrEqualToConstant: maxSize)
        ])
    }
}

protocol CallInfoViewControllerInput: CallActionsViewInputType, CallStatusViewInputType  {
    var accessoryType: CallInfoViewControllerAccessoryType { get }
}

final class CallInfoViewController: UIViewController, CallActionsViewDelegate {
    
    weak var delegate: CallInfoViewControllerDelegate?
    
    private let stackView = UIStackView(axis: .vertical)
    private let statusViewController: CallStatusViewController
    private let participantsViewController: CallParticipantsViewController
    private let avatarView = UserImageViewContainer(size: .big, maxSize: 240, yOffset: -8)
    private let actionsView = CallActionsView()
    
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 40
        
        addChildViewController(statusViewController)
        [statusViewController.view, avatarView, participantsViewController.view, actionsView].forEach(stackView.addArrangedSubview)
        statusViewController.didMove(toParentViewController: self)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuideOrFallback.bottomAnchor, constant: -32),
            actionsView.widthAnchor.constraint(greaterThanOrEqualToConstant: 256),
            actionsView.heightAnchor.constraint(lessThanOrEqualToConstant: 213),
            actionsView.heightAnchor.constraint(greaterThanOrEqualToConstant: 173),
            participantsViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }

    private func updateState() {
        actionsView.update(with: configuration)
        statusViewController.configuration = configuration
        avatarView.isHidden = !configuration.accessoryType.showAvatar
        avatarView.user = configuration.accessoryType.user
        participantsViewController.view.isHidden = configuration.accessoryType.showAvatar
        participantsViewController.viewModel = configuration.accessoryType
    }

    func callActionsView(_ callActionsView: CallActionsView, perform action: CallActionsViewAction) {
        Calling.log.debug("\(action) button tapped")
        delegate?.infoViewController(self, perform: CallAction.action(for: action))
    }
}
