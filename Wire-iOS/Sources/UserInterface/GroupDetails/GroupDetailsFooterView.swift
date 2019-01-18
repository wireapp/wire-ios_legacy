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

import UIKit

protocol GroupDetailsFooterViewDelegate: class {
    func detailsView(_ view: GroupDetailsFooterView, performAction: GroupDetailsFooterView.Action)
}

final class GroupDetailsFooterView: UIView {
    enum Action {
        case more, invite
    }
    
    weak var delegate: GroupDetailsFooterViewDelegate?
    
    private let variant: ColorSchemeVariant
    public let moreButton = IconButton()
    public let addButton = IconButton()
    
    init(variant: ColorSchemeVariant = ColorScheme.default.variant) {
        self.variant = variant
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [addButton, moreButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setIconColor(UIColor.from(scheme: .iconNormal), for: .normal)
            $0.setIconColor(UIColor.from(scheme: .iconHighlighted), for: .highlighted)
            $0.setIconColor(UIColor.from(scheme: .buttonFaded), for: .disabled)
            $0.setTitleColor(UIColor.from(scheme: .iconNormal), for: .normal)
            $0.setTitleColor(UIColor.from(scheme: .textDimmed), for: .highlighted)
            $0.setTitleColor(UIColor.from(scheme: .buttonFaded), for: .disabled)
            $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
        
        moreButton.setIcon(.ellipsis, with: .tiny, for: .normal)
        addButton.setIcon(.plus, with: .tiny, for: .normal)
        addButton.setTitle("participants.footer.add_title".localized.uppercased(), for: .normal)
        addButton.titleImageSpacing = 16
        addButton.titleLabel?.font = FontSpec(.small, .regular).font
        backgroundColor = UIColor.from(scheme: .barBackground)
        addButton.accessibilityIdentifier = "OtherUserMetaControllerLeftButton"
        moreButton.accessibilityIdentifier = "OtherUserMetaControllerRightButton"
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            addButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            moreButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            moreButton.leadingAnchor.constraint(greaterThanOrEqualTo: addButton.leadingAnchor, constant: 16)
        ])
    }
    
    @objc private func buttonTapped(_ sender: IconButton) {
        action(for: sender).apply {
            delegate?.detailsView(self, performAction: $0)
        }
    }
    
    private func action(for button: IconButton) -> Action? {
        switch button {
        case moreButton: return .more
        case addButton: return .invite
        default: return nil
        }
    }
    
    func update(for conversation: ZMConversation) {
        addButton.isHidden = ZMUser.selfUser().isGuest(in: conversation)
        addButton.isEnabled = conversation.freeParticipantSlots > 0
    }
}
