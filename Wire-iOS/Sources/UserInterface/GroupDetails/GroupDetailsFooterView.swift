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
import WireDataModel

protocol GroupDetailsFooterViewDelegate: AnyObject {
    func footerView(_ view: GroupDetailsFooterView, shouldPerformAction action: GroupDetailsFooterView.Action)
}

final class GroupDetailsFooterView: ConversationDetailFooterView {

    weak var delegate: GroupDetailsFooterViewDelegate?

    enum Action {
        case more, invite
    }

    func update(for conversation: GroupDetailsConversationType) {
        leftButton.isHidden = !SelfUser.current.canAddUser(to: conversation)
        leftButton.isEnabled = conversation.freeParticipantSlots > 0
    }

    override func setupButtons() {
        leftIcon = .plus
        leftButton.setTitle("participants.footer.add_title".localized(uppercased: true), for: .normal)
        leftButton.accessibilityIdentifier = "OtherUserMetaControllerLeftButton"
        rightIcon = .ellipsis
        rightButton.accessibilityIdentifier = "OtherUserMetaControllerRightButton"
    }

    override func leftButtonTapped(_ sender: IconButton) {
        delegate?.footerView(self, shouldPerformAction: .invite)
    }

    override func rightButtonTapped(_ sender: IconButton) {
        delegate?.footerView(self, shouldPerformAction: .more)
    }

}
