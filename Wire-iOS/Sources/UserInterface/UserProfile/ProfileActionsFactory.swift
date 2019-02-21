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

/**
 * The actions that can be performed from the profile details or devices.
 */

enum ProfileAction: Equatable {
    case createGroup
    case manageNotifications
    case archive
    case deleteContents
    case block
    case openOneToOne
    case removeFromGroup
    case connect
    case cancelConnectionRequest

    /// Whether the action is destructive.
    var isDestructive: Bool {
        switch self {
        case .deleteContents, .block, .removeFromGroup: return true
        default: return false
        }
    }

    /// The text of the button for this action.
    var buttonText: String {
        switch self {
        case .createGroup: return "profile.create_conversation_button_title".localized
        case .manageNotifications: return "profile_details.action.notifications".localized
        case .archive: return "meta.menu.archive".localized
        case .deleteContents: return "profile_details.action.delete".localized
        case .block: return "profile.block_dialog.button_block".localized
        case .openOneToOne: return "profile.open_conversation_button_title".localized
        case .removeFromGroup: return "profile.remove_dialog_button_remove".localized
        case .connect: return "profile.connection_request_dialog.button_connect".localized
        case .cancelConnectionRequest: return "meta.menu.cancel_connection_request".localized
        }
    }

    /// The icon of the button for this action.
    var buttonIcon: ZetaIconType {
        switch self {
        case .createGroup: return .createConversation
        case .manageNotifications: return .bell
        case .archive: return .archive
        case .deleteContents: return .delete
        case .block: return .block
        case .openOneToOne: return .conversation
        case .removeFromGroup: return .minus
        case .connect: return .plus
        case .cancelConnectionRequest: return .undo
        }
    }

}

/**
 * An object that returns the actions that a user can perform in the scope
 * of a conversation.
 */

class ProfileActionsFactory: NSObject {

    // MARK: - Environmemt

    /// The user that is displayed in the profile details.
    let user: GenericUser

    /// The user that wants to perform the actions.
    let viewer: GenericUser

    /// The conversation that the user wants to perform the actions in.
    let conversation: ZMConversation

    // MARK: - Initialization

    /**
     * Creates the action controller with the specified environment.
     * - parameter user: The user that is displayed in the profile details.
     * - parameter viewer: The user that wants to perform the actions.
     * - parameter conversation: The conversation that the user wants to
     * perform the actions in.
     */

    init(user: GenericUser, viewer: GenericUser, conversation: ZMConversation) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
    }

    // MARK: - Calculating the Actions

    /**
     * Calculates the list of actions to display to the user.
     */

    func makeActionsList() -> [ProfileAction] {
        // Do nothing if the user is viewing their own profile
        if viewer.isSelfUser && user.isSelfUser {
            return []
        }

        var actions: [ProfileAction] = []

        switch conversation.conversationType {
        case .oneOnOne:
            // All viewers except partners can start conversations
            if viewer.teamRole != .partner {
                actions.append(.createGroup)
            }

            // Notifications, Archive, Delete Contents if available for every 1:1
            actions.append(contentsOf: [.manageNotifications, .archive, .deleteContents])

            // If the viewer is not on the same team as the other user, allow blocking
            if !viewer.canAccessCompanyInformation(of: user) {
                actions.append(.block)
            }

        case .group:
            // Do nothing if the viewer is a wireless user because they can't have 1:1's
            if viewer.isWirelessUser {
                break
            }

            let isOnSameTeam = viewer.canAccessCompanyInformation(of: user)

            // Show connection request actions for unconnected users from different teams.
            if user.isPendingApprovalBySelfUser {
                // Do not show the action bar if the user is not connected.
                break
            } else if user.isPendingApprovalByOtherUser {
                actions.append(.cancelConnectionRequest)
            } else if user.isConnected || isOnSameTeam {
                actions.append(.openOneToOne)
            } else if user.canBeConnected {
                actions.append(.connect)
            }

            // Only non-guests and non-partners are allowed to remove
            if !viewer.isGuest(in: conversation) && viewer.teamRole != .partner {
                actions.append(.removeFromGroup)
            }

            // If the user is not from the same team as the other user, allow blocking
            if user.isConnected && !isOnSameTeam {
                actions.append(.block)
            }

        default:
            break
        }

        return actions
    }

}
