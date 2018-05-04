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
}

fileprivate extension CallInfoViewControllerInput {
    var overlayBackgroundColor: UIColor {
        switch (isVideoCall, state) {
        case (false, _): return .wr_color(fromColorScheme: ColorSchemeColorBackground, variant: variant)
        case (true, .ringingOutgoing), (true, .ringingIncoming): return UIColor.black.withAlphaComponent(0.4)
        case (true, _): return UIColor.black.withAlphaComponent(0.64)
        }
    }
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
            updateState(animated: true)
        }
    }

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

    private func updateState(animated: Bool = false) {
        actionsView.update(with: configuration)
        statusViewController.configuration = configuration
        avatarView.isHidden = !configuration.accessoryType.showAvatar
        avatarView.user = configuration.accessoryType.user
        participantsViewController.view.isHidden = configuration.accessoryType.showAvatar
        participantsViewController.viewModel = configuration.accessoryType
        participantsViewController.variant = configuration.effectiveColorVariant

        UIView.animate(withDuration: 0.2) { [view, configuration] in
            view?.backgroundColor = configuration.overlayBackgroundColor
        }
    }

    func callActionsView(_ callActionsView: CallActionsView, perform action: CallAction) {
        Calling.log.debug("\(action) button tapped")
        delegate?.infoViewController(self, perform: action)
    }
}
