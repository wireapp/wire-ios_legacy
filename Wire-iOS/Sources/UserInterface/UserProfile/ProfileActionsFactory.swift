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
    case mute(isMuted: Bool)
    case manageNotifications
    case archive
    case deleteContents
    case block(isBlocked: Bool)
    case openOneToOne
    case removeFromGroup
    case connect
    case cancelConnectionRequest

    /// The text of the button for this action.
    var buttonText: String {
        switch self {
        case .createGroup: return "profile.create_conversation_button_title".localized
        case .mute(let isMuted): return isMuted ? "meta.menu.silence.unmute".localized : "meta.menu.silence.mute".localized
        case .manageNotifications: return "meta.menu.configure_notifications".localized
        case .archive: return "meta.menu.archive".localized
        case .deleteContents: return "meta.menu.delete".localized
        case .block(let isBlocked): return isBlocked ? "profile.unblock_button_title".localized : "profile.block_button_title".localized
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
        case .manageNotifications, .mute: return .bell
        case .archive: return .archive
        case .deleteContents: return .delete
        case .block: return .block
        case .openOneToOne: return .conversation
        case .removeFromGroup: return .minus
        case .connect: return .plus
        case .cancelConnectionRequest: return .undo
        }
    }

    /// Whether the action can be used as a key action.
    var isEligibleForKeyAction: Bool {
        switch self {
        case .createGroup: return true
        case .manageNotifications, .mute: return false
        case .archive: return false
        case .deleteContents: return false
        case .block: return false
        case .openOneToOne: return true
        case .removeFromGroup: return false
        case .connect: return true
        case .cancelConnectionRequest: return true
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
    let conversation: ZMConversation?

    // MARK: - Initialization

    /**
     * Creates the action controller with the specified environment.
     * - parameter user: The user that is displayed in the profile details.
     * - parameter viewer: The user that wants to perform the actions.
     * - parameter conversation: The conversation that the user wants to
     * perform the actions in.
     */

    init(user: GenericUser, viewer: GenericUser, conversation: ZMConversation?) {
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

        // Do not show any action if the user is blocked
        if user.isBlocked {
            return [.block(isBlocked: true)]
        }

        // If there is no conversation, offer to connect to the user if possible
        guard let conversation = self.conversation else {
            if !user.isConnected {
                if user.isPendingApprovalByOtherUser {
                    return [.cancelConnectionRequest]
                } else {
                    return [.connect]
                }
            }

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
            let notificationAction: ProfileAction = viewer.isTeamMember ? .manageNotifications : .mute(isMuted: conversation.mutedMessageTypes != .none)
            actions.append(contentsOf: [notificationAction, .archive, .deleteContents])

            // If the viewer is not on the same team as the other user, allow blocking
            if !viewer.canAccessCompanyInformation(of: user) && !user.isWirelessUser {
                actions.append(.block(isBlocked: false))
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
            if user.isConnected && !isOnSameTeam && !user.isWirelessUser {
                actions.append(.block(isBlocked: false))
            }

        default:
            break
        }

        return actions
    }

}
