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

public enum ConversationListType {
    case archived, unarchived, pending, contacts, groups, favorites, folder(_ folder: LabelType)
}

public struct ConversationDirectoryChangeInfo {

    public var reloaded: Bool
    public var updatedLists: [ConversationListType]
    public var updatedFolders: Bool

    public init(reloaded: Bool, updatedLists: [ConversationListType], updatedFolders: Bool) {
        self.reloaded = reloaded
        self.updatedLists = updatedLists
        self.updatedFolders = updatedFolders
    }

}

public protocol ConversationDirectoryObserver: AnyObject {

    func conversationDirectoryDidChange(_ changeInfo: ConversationDirectoryChangeInfo)

}

public protocol ConversationDirectoryType {

    /// All folder created by the user
    var allFolders: [LabelType] { get }

    /// Create a new folder with a given name
    func createFolder(_ name: String) -> LabelType?

    /// Retrieve a conversation list by a given type
    func conversations(by: ConversationListType) -> [ZMConversation]

    /// Observe changes to the conversation lists & folders
    ///
    /// NOTE that returned token must be retained for as long you want the observer to be active
    func addObserver(_ observer: ConversationDirectoryObserver) -> Any

}

extension ZMConversationListDirectory: ConversationDirectoryType {

    public func conversations(by type: ConversationListType) -> [ZMConversation] {
        switch type {
        case .archived:
            return archivedConversations as! [ZMConversation]
        case .unarchived:
            return unarchivedConversations as! [ZMConversation]
        case .pending:
            return pendingConnectionConversations as! [ZMConversation]
        case .contacts:
            return oneToOneConversations as! [ZMConversation]
        case .groups:
            return groupConversations as! [ZMConversation]
        case .favorites:
            return favoriteConversations as! [ZMConversation]
        case .folder(let label):
            guard let objectID = (label as? Label)?.objectID else { return [] } // TODO jacob make optional?
            return listsByFolder[objectID] as? [ZMConversation] ?? []
        }
    }

    public func addObserver(_ observer: ConversationDirectoryObserver) -> Any {
        let observerProxy = ConversationListObserverProxy(observer: observer, directory: self)
        let listToken = ConversationListChangeInfo.addListObserver(observerProxy, for: nil, managedObjectContext: managedObjectContext)
        let reloadToken = ConversationListChangeInfo.addReloadObserver(observerProxy, managedObjectContext: managedObjectContext)
        let folderToken = ConversationListChangeInfo.addFolderObserver(observerProxy, managedObjectContext: managedObjectContext)

        return [folderToken, listToken, reloadToken, observerProxy]
    }

    @objc
    public func createFolder(_ name: String) -> LabelType? {
        var created = false
        let label = Label.fetchOrCreate(remoteIdentifier: UUID(), create: true, in: managedObjectContext, created: &created)
        label?.name = name
        label?.kind = .folder
        return label
    }

}

private class ConversationListObserverProxy: NSObject, ZMConversationListObserver, ZMConversationListReloadObserver, ZMConversationListFolderObserver {

    weak var observer: ConversationDirectoryObserver?
    var directory: ZMConversationListDirectory

    init(observer: ConversationDirectoryObserver, directory: ZMConversationListDirectory) {
        self.observer = observer
        self.directory = directory
    }

    func conversationListsDidReload() {
        observer?.conversationDirectoryDidChange(ConversationDirectoryChangeInfo(reloaded: true, updatedLists: [], updatedFolders: false))
    }

    func conversationListsDidChangeFolders() {
        observer?.conversationDirectoryDidChange(ConversationDirectoryChangeInfo(reloaded: false, updatedLists: [], updatedFolders: true))
    }

    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        let updatedLists: [ConversationListType]

        if changeInfo.conversationList === directory.oneToOneConversations {
            updatedLists = [.contacts]
        } else if changeInfo.conversationList === directory.groupConversations {
            updatedLists = [.groups]
        } else if changeInfo.conversationList === directory.archivedConversations {
            updatedLists = [.archived]
        } else if changeInfo.conversationList === directory.pendingConnectionConversations {
            updatedLists = [.pending]
        } else if changeInfo.conversationList === directory.unarchivedConversations {
            updatedLists = [.unarchived]
        } else if changeInfo.conversationList === directory.favoriteConversations {
            updatedLists = [.favorites]
        } else if let label = changeInfo.conversationList.label, label.kind == .folder {
            updatedLists = [.folder(label)]
        } else {
            updatedLists = []
        }

        observer?.conversationDirectoryDidChange(ConversationDirectoryChangeInfo(reloaded: false, updatedLists: updatedLists, updatedFolders: false))
    }

}
