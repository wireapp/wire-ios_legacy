//
//  ProfileFooterView.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 18.02.19.
//  Copyright © 2019 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit

@objc protocol ProfileFooterViewDelegate: class {
    func detailsView(_ view: ProfileFooterView, performAction: ProfileFooterView.Action)
}

@objcMembers
final class ProfileFooterView: ConversationDetailFooterView {

    weak var delegate: ProfileFooterViewDelegate?
    var user: ZMUser
    var conversation: ZMConversation
    var context: ProfileViewControllerContext
    
    public init(user: ZMUser, conversation: ZMConversation, context: ProfileViewControllerContext) {
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
            delegate?.detailsView(self, performAction: $0)
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
            if ZMUser.selfUserHas(permissions: .member) || !ZMUser.selfUser().isTeamMember {
                return .addPeople
            } else {
                return .none
            }
        } else if user.isTeamMember {
            return .openConversation
        } else if user.isBlocked {
            return .unblock
        } else if user.isPendingApprovalBySelfUser {
            return .acceptConnectionRequest
        } else if user.isPendingApprovalByOtherUser {
            return .cancelConnectionRequest
        } else if user.canBeConnected {
            return .sendConnectionRequest
        } else if user.isWirelessUser {
            return .none
        } else {
            return .openConversation
        }
    }
    
    var rightButtonAction: Action {
        if user.isSelfUser {
            return .none
        } else if context == .groupConversation {
            if ZMUser.selfUser().canRemoveUser(from: conversation) {
                return .removePeople
            } else {
                return .none
            }
        } else if user.isConnected {
            return .presentMenu
        } else if nil != user.team {
            return .presentMenu
        } else {
            return .none
        }
    }
    

    @objc enum Action: Int {
        case none, openConversation, addPeople, removePeople, block, presentMenu,
        unblock, acceptConnectionRequest, sendConnectionRequest, cancelConnectionRequest
        
        var buttonText: String {
            switch self {
            case .sendConnectionRequest, .acceptConnectionRequest:
                return "profile.connection_request_dialog.button_connect".localized
            case .cancelConnectionRequest:
                return "profile.cancel_connection_button_title".localized
            case .unblock:
                return "profile.connection_request_state.blocked".localized
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
            case .unblock:
                return .block
            case .block:
                return .block
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

