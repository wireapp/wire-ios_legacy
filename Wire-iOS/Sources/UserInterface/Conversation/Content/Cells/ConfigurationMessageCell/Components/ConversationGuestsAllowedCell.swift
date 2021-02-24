//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel

final class GuestsAllowedCellDescription: ConversationMessageCellDescription {

    typealias View = GuestsAllowedCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 16

    let isFullWidth: Bool = false
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init() {
        configuration = View.Configuration()
        actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}

final class GuestsAllowedCell: UIView, ConversationMessageCell {

    struct GuestsAllowedCellConfiguration { }

    typealias Configuration = GuestsAllowedCellConfiguration

    weak var delegate: ConversationMessageCellDelegate? = nil
    weak var message: ZMConversationMessage? = nil

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    let inviteButton = InviteButton()
    var isSelected: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        titleLabel.textColor = UIColor.from(scheme: .textForeground)
        titleLabel.font = FontSpec(.medium, .none).font

        inviteButton.setTitle("content.system.conversation.invite.button".localized, for: .normal)
        inviteButton.addTarget(self, action: #selector(inviteButtonTapped), for: .touchUpInside)
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

    func configure(with object: GuestsAllowedCellConfiguration, animated: Bool) {

    }

    @objc private func inviteButtonTapped(_ sender: UIButton) {
        delegate?.conversationMessageWantsToOpenGuestOptionsFromView(self, sourceView: self)
    }

}
