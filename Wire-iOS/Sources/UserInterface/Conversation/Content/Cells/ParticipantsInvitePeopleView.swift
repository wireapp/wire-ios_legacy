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

import Foundation

protocol ParticipantsInvitePeopleViewDelegate: class {
    func invitePeopleViewInviteButtonTapped(_ invitePeopleView: ParticipantsInvitePeopleView)
}

class ParticipantsInvitePeopleView: UIView {
    
    weak var delegate: ParticipantsInvitePeopleViewDelegate?
    
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    let inviteButton = IconButton()
    
    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        addSubview(stackView)
        [titleLabel, inviteButton].forEach(stackView.addArrangedSubview)
        titleLabel.numberOfLines = 0
        titleLabel.text = "content.system.conversation.invite.title".localized
        titleLabel.textColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground)
        titleLabel.font = FontSpec(.medium, .regular).font
        inviteButton.setTitle("content.system.conversation.invite.button".localized, for: .normal)
        inviteButton.setTitleColor(.wr_color(fromColorScheme: ColorSchemeColorTextForeground), for: .normal)
        inviteButton.adjustsTitleWhenHighlighted = true
        inviteButton.setBackgroundImageColor(.init(red: 0.612, green: 0.655, blue: 0.686, alpha: 0.2), for: .normal)
        inviteButton.clipsToBounds = true
        inviteButton.titleLabel?.font = FontSpec(.normal, .semibold).font
        inviteButton.addTarget(self, action: #selector(inviteButtonTapped), for: .touchUpInside)
        inviteButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        inviteButton.layer.cornerRadius = 4
    }
    
    private func createConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    @objc private func inviteButtonTapped(_ sender: UIButton) {
        delegate?.invitePeopleViewInviteButtonTapped(self)
    }
}
