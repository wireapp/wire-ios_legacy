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
    public static let didChangeNotificationName = Notification.Name(rawValue: "SpaceDidChangeNotificationName")
    public static let didChangeNotificationNameString = didChangeNotificationName.rawValue
    public let name: String
    public let image: UIImage?
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
    
    init(name: String, image: UIImage?, predicate: NSPredicate) {
        self.name = name
        self.image = image
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

    @objc(joinSpaceNamed:)
    static func joinSpace(named spaceName: String) {
        if let factory = SettingsPropertyFactory.shared {
            
            var workspaceNameProperty = factory.property(.workspaceName)
            
            try? workspaceNameProperty << spaceName
            
            self.update()
        }
    }
    
    public static func update() {
        if let factory = SettingsPropertyFactory.shared,
            let workspaceName = factory.property(.workspaceName).rawValue() as? String,
            !workspaceName.isEmpty {
            
            let privateSpace: Space = {
                let selfUser = ZMUser.selfUser()
                
                var image: UIImage? = .none
                
                if let imageData = selfUser?.imageMediumData {
                    image = UIImage(from: imageData, withMaxSize: 100)
                }
                
                let predicate = NSPredicate(format: "NOT (displayName CONTAINS[cd] %@)", workspaceName)
                let privateSpace = Space(name: selfUser?.displayName ?? "", image: image, predicate: predicate)
                privateSpace.selected = true
                return privateSpace
            }()
            
            let workSpace: Space = {
                let predicate = NSPredicate(format: "displayName CONTAINS[cd] %@", workspaceName)
                let workSpace = Space(name: workspaceName, image: UIImage(named: "wire-logo-shield"), predicate: predicate)
                workSpace.selected = true
                return workSpace
            }()
            
            spaces = [privateSpace, workSpace]
        }
        else {
            spaces = []
        }
        
        NotificationCenter.default.post(name: didChangeNotificationName, object: .none)
    }
    
    public static var spaces: [Space] = []
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

