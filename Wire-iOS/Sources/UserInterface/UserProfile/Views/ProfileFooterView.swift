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

@objc protocol ProfileFooterViewDelegate: class {
    func footerView(_ view: ProfileFooterView, performs action: ProfileFooterView.Action)
}

@objcMembers
final class ProfileFooterView: ConversationDetailFooterView {

    weak var delegate: ProfileFooterViewDelegate?
    var user: GenericUser
    var conversation: ZMConversation
    var context: ProfileViewControllerContext
    
    public init(user: GenericUser, conversation: ZMConversation, context: ProfileViewControllerContext) {
        self.user = user
        self.conversation = conversation
        self.context = context
        super.init(mainButton: IconButton())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupButtons() {
        leftButton.accessibilityIdentifier = "left_button"
        rightButton.accessibilityIdentifier = "right_button"
        
        leftButton.setTitle(leftButtonAction.buttonText.uppercased(), for: .normal)
        leftIcon = leftButtonAction.iconType
        rightIcon = rightButtonAction.iconType
    }
    
    override func buttonTapped(_ sender: IconButton) {
        action(for: sender).apply {
            delegate?.footerView(self, performs: $0)
        }
    }
    
    private func action(for button: IconButton) -> Action? {
        switch button {
        case rightButton: return rightButtonAction
        case leftButton: return leftButtonAction
        default: return nil
        }
    }

    var leftButtonAction: Action {
        if user.isSelfUser {
            return .none
        } else if (user.isConnected || user.isTeamMember) &&
            context == .oneToOneConversation {
            if user.has(permissions: .member) || !user.isTeamMember {
                return .addPeople
            } else {
                return .none
            }
        } else if user.isTeamMember {
            return .openConversation
        } else if user.isBlocked {
            return .none
        } else if user.isPendingApprovalBySelfUser {
            return .acceptConnectionRequest
        } else if user.isPendingApprovalByOtherUser {
            return .cancelConnectionRequest
        } else if user.canBeConnected {
            return .sendConnectionRequest
        } else if user.isWirelessUser {
            return .none
        } else if !user.isConnected {
            return .none
        } else {
            return .openConversation
        }
    }
    
    var rightButtonAction: Action {
        if user.isSelfUser {
            return .none
        } else if context == .groupConversation {
            if user.canRemoveUser(from: conversation) {
                return .removePeople
            } else {
                return .none
            }
        } else if user.isConnected {
            return .presentMenu
        } else if user.isTeamMember {
            return .presentMenu
        } else {
            return .none
        }
    }
    

    @objc enum Action: Int {
        case none, openConversation, addPeople, removePeople, presentMenu,
        acceptConnectionRequest, sendConnectionRequest, cancelConnectionRequest //block, unblock,
        
        var buttonText: String {
            switch self {
            case .sendConnectionRequest, .acceptConnectionRequest:
                return "profile.connection_request_dialog.button_connect".localized
            case .cancelConnectionRequest:
                return "profile.cancel_connection_button_title".localized
            case .addPeople:
                return "profile.create_conversation_button_title".localized
            case .openConversation:
                return "profile.open_conversation_button_title".localized
            default: return ""
            }
        }
        
        var iconType: ZetaIconType {
            switch self {
            case .addPeople:
                return .createConversation
            case .presentMenu:
                return .ellipsis
            case .removePeople:
                return .ellipsis
            case .cancelConnectionRequest:
                return .undo
            case .openConversation:
                return .conversation
            case .sendConnectionRequest,
                 .acceptConnectionRequest:
                return .plus
            default:
                return .none
            }
        }
        
    }
}

