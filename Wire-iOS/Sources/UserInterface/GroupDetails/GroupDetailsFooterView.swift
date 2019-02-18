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

final class GroupDetailsFooterView: ConversationDetailFooterView {
    
    weak var delegate: GroupDetailsFooterViewDelegate?
    
    enum Action {
        case more, invite
    }
    
    init() {
        super.init(mainButton: RestrictedIconButton(requiredPermissions: .member))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func action(for button: IconButton) -> Action? {
        switch button {
        case rightButton: return .more
        case leftButton: return .invite
        default: return nil
        }
    }
    
    func update(for conversation: ZMConversation) {
        leftButton.isHidden = ZMUser.selfUser().isGuest(in: conversation)
        leftButton.isEnabled = conversation.freeParticipantSlots > 0
    }
    
    override func setupButtons() {
        leftIcon = .plus
        leftButton.setTitle("participants.footer.add_title".localized.uppercased(), for: .normal)
        leftButton.accessibilityIdentifier = "OtherUserMetaControllerLeftButton"
        rightIcon = .ellipsis
        rightButton.accessibilityIdentifier = "OtherUserMetaControllerRightButton"
    }
    
    override func buttonTapped(_ sender: IconButton) {
        action(for: sender).apply {
            delegate?.detailsView(self, performAction: $0)
        }
    }
}
