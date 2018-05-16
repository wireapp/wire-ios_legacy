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

protocol CallAccessoryViewControllerDelegate: class {
    func callAccessoryViewControllerDidSelectShowMore(viewController: CallAccessoryViewController)
}

final class CallAccessoryViewController: UIViewController, CallParticipantsViewControllerDelegate {
    
    weak var delegate: CallAccessoryViewControllerDelegate?
    private let participantsViewController: CallParticipantsViewController
    private let avatarView = UserImageViewContainer(size: .big, maxSize: 240, yOffset: -8)
    
    var configuration: CallInfoViewControllerInput {
        didSet {
            updateState()
        }
    }
    
    init(configuration: CallInfoViewControllerInput) {
        self.configuration = configuration
        participantsViewController = CallParticipantsViewController(participants: configuration.accessoryType.participants, allowsScrolling: false)
        super.init(nibName: nil, bundle: nil)
        participantsViewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateState()
    }
    
    private func setupViews() {
        addToSelf(participantsViewController)
        view.addSubview(avatarView)
    }
    
    private func createConstraints() {
        participantsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        participantsViewController.view.fitInSuperview()
        avatarView.fitInSuperview()
    }
    
    private func updateState() {
        switch configuration.accessoryType {
        case .avatar(let user): avatarView.user = user
        case .participantsList(let participants): participantsViewController.participants = participants
        case .none: break
        }
        
        avatarView.isHidden = !configuration.accessoryType.showAvatar
        participantsViewController.view.isHidden = !configuration.accessoryType.showParticipantList
        participantsViewController.variant = configuration.effectiveColorVariant
    }
    
    func callParticipantsViewControllerDidSelectShowMore(viewController: CallParticipantsViewController) {
        delegate?.callAccessoryViewControllerDidSelectShowMore(viewController: self)
    }

}
