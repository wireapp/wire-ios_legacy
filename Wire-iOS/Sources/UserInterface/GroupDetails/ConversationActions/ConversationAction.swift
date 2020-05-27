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

import Foundation
import WireDataModel

extension ZMConversation {
    enum Action: Equatable {
        
        case deleteGroup
        case moveToFolder
        case removeFromFolder(folder: String)
        case clearContent
        case leave
        case configureNotifications
        case silence(isSilenced: Bool)
        case archive(isArchived: Bool)
        case cancelRequest
        case block(isBlocked: Bool)
        case markRead
        case markUnread
        case remove
        case favorite(isFavorite: Bool)
    }
    
    var listActions: [Action] {
        return actions.filter({ $0 != .deleteGroup })
    }
    
    var detailActions: [Action] {
        return actions.filter({ $0 != .configureNotifications})
    }
    
    private var actions: [Action] {
        switch conversationType {
        case .connection:
            return availablePendingActions()
        case .oneOnOne:
            return availableOneToOneActions()
        case .self,
             .group,
             .invalid:
            return availableGroupActions()
        }
    }
    
    private func availableOneToOneActions() -> [Action] {
        precondition(conversationType == .oneOnOne)
        var actions = [Action]()
        actions.append(contentsOf: availableStandardActions())
        actions.append(.clearContent)
        if teamRemoteIdentifier == nil, let connectedUser = connectedUser {
            actions.append(.block(isBlocked: connectedUser.isBlocked))
        }
        return actions
    }
    
    private func availablePendingActions() -> [Action] {
        precondition(conversationType == .connection)
        return [.archive(isArchived: isArchived), .cancelRequest]
    }
    
    private func availableGroupActions() -> [Action] {
        var actions = availableStandardActions()
        actions.append(.clearContent)

        if localParticipants.contains(ZMUser.selfUser()) {
            actions.append(.leave)
        }

        if ZMUser.selfUser()?.canDeleteConversation(self) == true {
            actions.append(.deleteGroup)
        }

        return actions
    }
    
    private func availableStandardActions() -> [Action] {
        var actions = [Action]()
        
        if let markReadAction = markAsReadAction() {
            actions.append(markReadAction)
        }
        
        if !isReadOnly {
            if ZMUser.selfUser()?.isTeamMember ?? false {
                actions.append(.configureNotifications)
            }
            else {
                let isSilenced = mutedMessageTypes != .none
                actions.append(.silence(isSilenced: isSilenced))
            }
        }

        actions.append(.archive(isArchived: isArchived))

        if !isArchived {
            actions.append(.favorite(isFavorite: isFavorite))
            actions.append(.moveToFolder)
            
            if let folderName = folder?.name {
                actions.append(.removeFromFolder(folder: folderName))
            }
        }

        return actions
    }
    
    private func markAsReadAction() -> Action? {
        guard Bundle.developerModeEnabled else { return nil }
        if unreadMessages.count > 0 {
            return .markRead
        } else if unreadMessages.count == 0 && canMarkAsUnread() {
            return .markUnread
        }
        return nil
    }
}

extension ZMConversation.Action {

    fileprivate var isDestructive: Bool {
        switch self {
        case .remove,
             .deleteGroup:
            return true
        default: return false
        }
    }
    
    var title: String {
        switch self {
        case .removeFromFolder(let folder):
            return localizationKey.localized(args: folder)
        default:
            return localizationKey.localized
        }
    }
    
    private var localizationKey: String {
        switch self {
        case .deleteGroup: return "meta.menu.delete"
        case .moveToFolder: return "meta.menu.move_to_folder"
        case .removeFromFolder: return "meta.menu.remove_from_folder"
        case .remove: return "profile.remove_dialog_button_remove"
        case .clearContent: return "meta.menu.clear_content"
        case .leave: return "meta.menu.leave"
        case .markRead: return "meta.menu.mark_read"
        case .markUnread: return "meta.menu.mark_unread"
        case .configureNotifications: return "meta.menu.configure_notifications"
        case .silence(isSilenced: let muted): return "meta.menu.silence.\(muted ? "unmute" : "mute")"
        case .archive(isArchived: let archived): return "meta.menu.\(archived ? "unarchive" : "archive")"
        case .cancelRequest: return "meta.menu.cancel_connection_request"
        case .block(isBlocked: let blocked): return blocked ? "profile.unblock_button_title" : "profile.block_button_title"
        case .favorite(isFavorite: let favorited): return favorited ? "profile.unfavorite_button_title" : "profile.favorite_button_title"
        }
    }
    
    func alertAction(handler: @escaping () -> Void) -> UIAlertAction {
        return .init(title: title, style: isDestructive ? .destructive : .default) { _ in handler() }
    }

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    func previewAction(handler: @escaping () -> Void) -> UIPreviewAction {
        return .init(title: title, style: isDestructive ? .destructive : .default, handler: { _, _ in handler() })
    }
}
