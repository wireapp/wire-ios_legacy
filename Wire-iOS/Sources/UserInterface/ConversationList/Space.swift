//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


@objc internal protocol SpaceUnreadObserver: class {
    func spaceDidChangeUnread(space: Space)
}

@objc internal protocol SpaceSelectionObserver: class {
    func spaceDidChangeSelection(space: Space)
}

internal class Space: NSObject {
    public let name: String
    public let predicate: NSPredicate
    public var selected: Bool = false {
        didSet {
            NotificationCenter.default.post(name: type(of: self).didChangeSelectionNotification, object: self)
        }
    }
    
    fileprivate static let didChangeUnreadNotification = Notification.Name("SpaceDidChangeUnreadNotification")
    fileprivate static let didChangeSelectionNotification = Notification.Name("SpaceDidChangeSelectionNotification")

    private var observerToken: NSObjectProtocol!
    
    deinit {
        ConversationListChangeInfo.remove(observer: self, for: self.conversationList)
    }
    
    init(name: String, predicate: NSPredicate) {
        self.name = name
        self.predicate = predicate
        
        super.init()
        
        observerToken = ConversationListChangeInfo.add(observer: self, for: self.conversationList)
    }
    
    var conversationList: ZMConversationList {
        return SessionObjectCache.shared().conversationList
    }
    
    var spaceConversations: [ZMConversation] {
        return self.conversationList.filtered(using: self.predicate).flatMap { $0 as? ZMConversation }
    }
    
    func hasUnreadMessages() -> Bool {
        return spaceConversations.map { $0.estimatedUnreadCount }.reduce(0, +) > 0
    }
    
    func isSpaceConversation(_ conversation: ZMConversation) -> Bool {
        return self.predicate.evaluate(with: conversation)
    }
    
    func addUnreadObserver(_ observer: SpaceUnreadObserver) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: type(of: self).didChangeUnreadNotification,
                                                      object: self,
                                                      queue: nil,
                                                      using: {[weak observer, weak self] _ in
                                                        guard let observer = observer, let `self` = self else {
                                                            return
                                                        }
                                                        observer.spaceDidChangeUnread(space: self)
        })
    }
    
    func addSelectionObserver(_ observer: SpaceSelectionObserver) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: type(of: self).didChangeSelectionNotification,
                                                      object: self,
                                                      queue: nil,
                                                      using: {[weak observer, weak self] _ in
                                                        guard let observer = observer, let `self` = self else {
                                                            return
                                                        }
                                                        observer.spaceDidChangeSelection(space: self)
        })
    }
    
    
    public static let workString = "ω"
    public static let familyString = "Ω"
    
    public static let privateSpace: Space = {
        let predicate = NSPredicate(format: "NOT (displayName CONTAINS %@) AND NOT (displayName CONTAINS %@)", workString, familyString)
        let privateSpace = Space(name: "Personal", predicate: predicate)
        privateSpace.selected = true
        return privateSpace
    }()
    
    public static let workSpace: Space = {
        let predicate = NSPredicate(format: "displayName CONTAINS %@", workString)
        let workSpace = Space(name: "Work", predicate: predicate)
        workSpace.selected = true
        return workSpace
    }()
    
    public static let familySpace: Space = {
        let predicate = NSPredicate(format: "displayName CONTAINS %@", familyString)
        let workSpace = Space(name: "Family", predicate: predicate)
        workSpace.selected = true
        return workSpace
    }()
    
    public static let spaces: [Space] = { [privateSpace, workSpace, familySpace] }()
    
    @objc(enableSpaces) public static let enableSpaces: Bool = DeveloperMenuState.developerMenuEnabled()
}

extension ZMConversation {
    func isMember(of space: Space) -> Bool {
        return space.isSpaceConversation(self)
    }
}

extension Space: ZMConversationListObserver {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        // TODO: check if the notification is necessary
        NotificationCenter.default.post(name: type(of: self).didChangeUnreadNotification, object: self)
    }
    
    func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        // TODO: check if the notification is necessary
        NotificationCenter.default.post(name: type(of: self).didChangeUnreadNotification, object: self)
    }
}

