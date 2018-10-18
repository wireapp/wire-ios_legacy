//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

protocol TeamInviteTopbarDelegate: class {
    func teamInviteTopBarDidTapButton(_ topBar: TeamInviteTopBar)
}

final class TeamInviteTopBar: UIView {
    enum ButtonMode {
        case skip, done
        
        var title: String {
            switch self {
            case .skip: return "team.invite.top_bar.skip".localized.uppercased()
            case .done: return "team.invite.top_bar.done".localized.uppercased()
            }
        }
    }
    
    weak var delegate: TeamInviteTopbarDelegate?
    private let actionButton = Button()
    
    var mode: ButtonMode = .skip {
        didSet {
            updateButtonMode()
        }
    }
    
    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor.Team.background
        addSubview(actionButton)
        actionButton.titleLabel?.font = FontSpec(.medium, .semibold).font!
        actionButton.accessibilityLabel = "continue"
        actionButton.setTitleColor(.black, for: .normal)
        actionButton.setTitleColor(.darkGray, for: .highlighted)
        actionButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        updateButtonMode()
    }
    
    private func createConstraints() {
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        let constraints: [NSLayoutConstraint] = [
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: 44)
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    private func updateButtonMode() {
        actionButton.setTitle(mode.title, for: .normal)
    }
    
    @objc private func didTapButton(_ sender: Button) {
        delegate?.teamInviteTopBarDidTapButton(self)
    }
}
