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

@objcMembers public class MockTeamConversationEvent: NSObject {
    
    public enum Kind: String {
        case create = "team.conversation-create"
        case delete = "team.conversation-delete"
    }
    
    public let data: [String : String]
    public let teamIdentifier: String
    public let conversationIdentifier: String
    public let kind: Kind
    public let timestamp = Date()

    public static func createIfNeeded(team: MockTeam, changedValues: [String: Any]) -> [MockTeamConversationEvent] {
        let conversationsKey = #keyPath(MockTeam.conversations)
        let oldConversations = team.committedValues(forKeys: [conversationsKey])
        
        guard let currentConversations = changedValues[conversationsKey] as? Set<MockConversation> else { return [] }
        guard let previousConversations = oldConversations[conversationsKey] as? Set<MockConversation> else { return [] }
        
        let removedConversationsEvents = previousConversations
            .subtracting(currentConversations)
            .map { MockTeamConversationEvent(kind: .delete, team: team, conversation: $0) }
        
        let addedConversationsEvents = currentConversations
            .subtracting(previousConversations)
            .map { MockTeamConversationEvent(kind: .create, team: team, conversation: $0) }
        
        return removedConversationsEvents + addedConversationsEvents
    }
    
    public init(kind: Kind, team: MockTeam, conversation: MockConversation) {
        self.kind = kind
        self.teamIdentifier = team.identifier
        self.conversationIdentifier = conversation.identifier
        self.data = [
            "conv" : conversation.identifier
        ]
    }
    
    @objc public var payload: ZMTransportData {
        return [
            "team" : teamIdentifier,
            "time" : timestamp.transportString(),
            "type" : kind.rawValue,
            "data" : data
            ] as ZMTransportData
    }
    
    public override var debugDescription: String {
        return "<\(type(of: self))> = \(kind.rawValue) team \(teamIdentifier) data: \(data)"
    }
}
