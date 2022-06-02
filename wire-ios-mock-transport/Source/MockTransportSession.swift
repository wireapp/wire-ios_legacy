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
import CoreData
import WireTransport

public extension MockTransportSession {
    private func selfUserPartOfTeam(_ team: MockTeam) -> Bool {
        return team.contains(user: selfUser)
    }
    
    private func ascendingCreationDate(first: MockTeam, second: MockTeam) -> Bool {
        return first.createdAt < second.createdAt
    }
    
    @objc(pushEventsForTeamsWithInserted:updated:deleted:shouldSendEventsToSelfUser:)
    func pushEventsForTeams(inserted: Set<NSManagedObject>, updated: Set<NSManagedObject>, deleted: Set<NSManagedObject>, shouldSendEventsToSelfUser: Bool) -> [MockPushEvent] {
        guard shouldSendEventsToSelfUser else { return [] }
        
        let updatedEvents =  updated
            .compactMap { $0 as? MockTeam }
            .sorted(by: ascendingCreationDate)
            .flatMap{ self.pushEventForUpdatedTeam(team: $0, insertedObjects: inserted) }
        
        let deletedEvents = deleted
            .compactMap { $0 as? MockTeam }
            .sorted(by: ascendingCreationDate)
            .filter(selfUserPartOfTeam)
            .map(MockTeamEvent.deleted)
            .map { MockPushEvent(with: $0.payload, uuid: UUID.create(), isTransient: false) }
        
        return updatedEvents + deletedEvents
    }
    
    private func pushEventForUpdatedTeam(team: MockTeam, insertedObjects: Set<NSManagedObject>) -> [MockPushEvent] {
        var allEvents = [MockPushEvent]()
        let changedValues = team.changedValues()
        if let teamUpdateEvent = MockTeamEvent.updated(team: team , changedValues: changedValues) {
            allEvents.append(MockPushEvent(with: teamUpdateEvent.payload, uuid: UUID.create(), isTransient: false) )
        }
        
        let membersEvents = MockTeamMemberEvent.createIfNeeded(team: team, changedValues: team.changedValues(), selfUser: selfUser)
        let membersPushEvents = membersEvents.compactMap{ $0 }.map { MockPushEvent(with: $0.payload, uuid: UUID.create(), isTransient: false) }
        allEvents.append(contentsOf: membersPushEvents)

        let conversationsEvents = MockTeamConversationEvent.createIfNeeded(team: team, changedValues: team.changedValues())
        let conversationsPushEvents = conversationsEvents.compactMap{ $0 }.map { MockPushEvent(with: $0.payload, uuid: UUID.create(), isTransient: false) }
        allEvents.append(contentsOf: conversationsPushEvents)
        
        return allEvents
    }
}

// MARK: - Conversations
extension MockTransportSession {

    func relevant(conversations: Set<NSManagedObject>) -> [MockConversation] {
        return conversations
            .compactMap { object -> MockConversation? in
                object as? MockConversation
            }.filter { conversation -> Bool in
                conversation.type != .invalid && conversation.selfIdentifier == self.selfUser.identifier
            }
    }

    @objc(pushEventsForInsertedConversations:updated:shouldSendEventsToSelfUser:)
    public func pushEventsForConversations(inserted: Set<NSManagedObject>, updated: Set<NSManagedObject>, shouldSendEventsToSelfUser: Bool) -> [MockPushEvent] {
        guard shouldSendEventsToSelfUser else { return [] }

        let insertedPayloads: [ZMTransportData] = relevant(conversations: inserted)
            .filter { conversation -> Bool in
                if let team = conversation.team {
                    return !team.contains(user: self.selfUser) // Team conversations where you are a member are handled separately
                } else {
                    return true
                }
            }
            .map { conversation -> ZMTransportData in
                let payload: [String: Any] = [
                    "type" : "conversation.create",
                    "data" : conversation.transportData(),
                    "conversation" : conversation.identifier,
                    "time" : Date().transportString()
                ]
                return payload as ZMTransportData
            }

        let updatedPayloads: [ZMTransportData] = relevant(conversations: updated)
            .filter { conversation -> Bool in
                conversation.changePushPayload != nil
            }
            .map { conversation -> ZMTransportData in
                let payload: [String: Any] = [
                    "type" : "conversation.access-update",
                    "data" : conversation.changePushPayload!,
                    "conversation" : conversation.identifier,
                    "time" : Date().transportString()
                ]
                return payload as ZMTransportData
            }

        let insertedEvents = (insertedPayloads + updatedPayloads)
            .map { payload -> MockPushEvent in
                MockPushEvent(with: payload, uuid: NSUUID.timeBasedUUID() as UUID, isTransient: false, isSilent: false)
            }

        return insertedEvents
    }
}


extension MockTransportSession : UnauthenticatedTransportSessionProtocol {

    public func enqueueRequest(withGenerator generator: () -> ZMTransportRequest?) -> EnqueueResult {
        let result = attemptToEnqueueSyncRequest(generator: generator)
        
        if !result.didHaveLessRequestThanMax {
            return .maximumNumberOfRequests
        }
        else if !result.didGenerateNonNullRequest {
            return .nilRequest
        }
        else {
            return .success
        }
    }
    
    public var environment: BackendEnvironmentProvider {
        return MockEnvironment()
    }
}


// MARK: - Email activation
public extension MockTransportSession {
    @objc var emailActivationCode: String {
        return "123456"
    }
}

extension MockTransportSession: TransportSessionType {
    
    public var requestLoopDetectionCallback: ((String) -> Void)? {
        set { }
        get { return nil }
    }
        
    public func addCompletionHandlerForBackgroundSession(identifier: String, handler: @escaping () -> Void) {
        
    }
        
}
