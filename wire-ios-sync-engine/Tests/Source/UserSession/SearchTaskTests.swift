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

@testable import WireSyncEngine

class SearchTaskTests: DatabaseTest {

    var teamIdentifier: UUID!
    var mockTransportSession: MockTransportSession!

    override func setUp() {
        super.setUp()
        self.mockTransportSession = MockTransportSession(dispatchGroup: self.dispatchGroup)
        self.teamIdentifier = UUID()

        performPretendingUIMocIsSyncMoc { [unowned self] in
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.teamIdentifier = self.teamIdentifier
            guard let team = Team.fetchOrCreate(with: self.teamIdentifier, create: true, in: self.uiMOC, created: nil) else { XCTFail(); return }
            _ = Member.getOrCreateMember(for: selfUser, in: team, context: self.uiMOC)
            uiMOC.saveOrRollback()
        }

        APIVersion.current = .v0
    }

    override func tearDown() {
        self.teamIdentifier = nil
        self.mockTransportSession = nil
        APIVersion.current = nil
        super.tearDown()
    }

    func createConnectedUser(withName name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = name
        user.remoteIdentifier = UUID.create()

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = user
        connection.status = .accepted

        uiMOC.saveOrRollback()

        return user
    }

    func createGroupConversation(withName name: String) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Me"
        conversation.userDefinedName = name
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        uiMOC.saveOrRollback()

        return conversation
    }

    func testThatItFindsASingleUnconnectedUserByHandle() {

        // given
        let remoteResultArrived = expectation(description: "received remote result")

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let mockUser = remoteChanges.insertUser(withName: "Dale Cooper")
            mockUser.handle = "bob"
        }

        let request = SearchRequest(query: "bob", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            remoteResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
            let user = result.directory.first
            XCTAssertEqual(user?.name, "Dale Cooper")
            XCTAssertEqual(user?.handle, "bob")
        }

        // when
        task.performRemoteSearchForTeamUser()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

    }

    func testThatItReturnsNothingWhenSearchingForSelfUserByHandle() {

        // given
        var selfUserID: UUID!

        // create self user remotely
        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let selfUser = remoteChanges.insertSelfUser(withName: "albert")
            selfUser.handle = "einstein"
            selfUserID = UUID(uuidString: selfUser.identifier)!
        }

        // update self user locally
        syncMOC.performGroupedBlockAndWait {
            ZMUser.selfUser(in: self.syncMOC).remoteIdentifier = selfUserID
            self.syncMOC.saveOrRollback()
        }

        let remoteResultArrived = expectation(description: "received remote result")
        let request = SearchRequest(query: "einstein", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            remoteResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 0)
        }

        // when
        task.performRemoteSearchForTeamUser()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Contacts Search

    func testThatItFindsASingleUser() {

        // given
        let resultArrived = expectation(description: "received result")
        let user = createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "userA", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotFindUsersContainingButNotBeginningWithSearchString() {
        // given
        let resultArrived = expectation(description: "received result")
        _ = createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "serA", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.count, 0)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsUsersBeginningWithSearchString() {
        // given
        let resultArrived = expectation(description: "received result")
        let user = createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "user", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItUsesAllQueryComponentsToFindAUser() {
        // given
        let resultArrived = expectation(description: "received result")
        let user1 = createConnectedUser(withName: "Some Body")
        _ = createConnectedUser(withName: "Some")
        _ = createConnectedUser(withName: "Any Body")

        let request = SearchRequest(query: "Some Body", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsSeveralUsers() {
        // given
        let resultArrived = expectation(description: "received result")
        let user1 = createConnectedUser(withName: "Grant")
        let user2 = createConnectedUser(withName: "Greg")
        _ = createConnectedUser(withName: "Bob")

        let request = SearchRequest(query: "Gr", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1, user2])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatUserSearchIsCaseInsensitive() {
        // given
        let resultArrived = expectation(description: "received result")
        let user1 = createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "someBodY", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatUserSearchIsInsensitiveToDiacritics() {
        // given
        let resultArrived = expectation(description: "received result")
        let user1 = createConnectedUser(withName: "Sömëbodÿ")

        let request = SearchRequest(query: "Sømebôdy", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatUserSearchOnlyReturnsConnectedUsers() {
        // given
        let resultArrived = expectation(description: "received result")
        let user1 = createConnectedUser(withName: "Somebody Blocked")
        user1.connection?.status = .blocked
        let user2 = createConnectedUser(withName: "Somebody Pending")
        user2.connection?.status = .pending
        let user3 = createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "Some", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user3])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotReturnTheSelfUser() {
        // given
        let resultArrived = expectation(description: "received result")
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Some self user"
        let user = createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "Some", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Team member local search

    func testThatItCanSearchForTeamMembersLocally() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let user = ZMUser.insertNewObject(in: uiMOC)
        let member = Member.insertNewObject(in: uiMOC)

        user.name = "Member A"

        member.team = team
        member.user = user

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "@member", searchOptions: [.teamMembers], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [user])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCanExcludeNonActiveTeamMembersLocally() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let userB = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC)
        let memberB = Member.insertNewObject(in: uiMOC) // non-active team-member
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID()
        conversation.addParticipantsAndUpdateConversationState(users: Set([userA, ZMUser.selfUser(in: uiMOC)]), role: nil)

        userA.name = "Member A"
        userB.name = "Member B"

        memberA.team = team
        memberA.user = userA

        memberB.team = team
        memberB.user = userB

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActiveTeamMembers], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItIncludesNonActiveTeamMembersLocally_WhenSelfUserWasCreatedByThem() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC) // non-active team-member
        let selfUser = ZMUser.selfUser(in: uiMOC)

        userA.name = "Member A"
        userA.handle = "abc"

        selfUser.membership?.permissions = .partner
        selfUser.membership?.createdBy = userA

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .admin

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActiveTeamMembers], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCanExcludeNonActivePartnersLocally() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let userB = ZMUser.insertNewObject(in: uiMOC)
        let userC = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC)
        let memberB = Member.insertNewObject(in: uiMOC) // active partner
        let memberC = Member.insertNewObject(in: uiMOC) // non-active partner
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID()
        conversation.addParticipantsAndUpdateConversationState(users: Set([userA, userB, ZMUser.selfUser(in: self.uiMOC)]), role: nil)

        userA.name = "Member A"
        userB.name = "Member B"
        userC.name = "Member C"

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .member

        memberB.team = team
        memberB.user = userB
        memberB.permissions = .partner

        memberC.team = team
        memberC.user = userC
        memberC.permissions = .partner

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA, userB])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItIncludesNonActivePartnersLocally_WhenSearchingWithExactHandle() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC) // non-active partner

        userA.name = "Member A"
        userA.handle = "abc"

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .partner

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "@abc", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItIncludesNonActivePartnersLocally_WhenSelfUserCreatedPartner() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC) // non-active partner

        userA.name = "Member A"
        userA.handle = "abc"

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .partner
        memberA.createdBy = ZMUser.selfUser(in: uiMOC)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Conversation Search

    func testThatItFindsASingleConversation() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation = createGroupConversation(withName: "Somebody")

        let request = SearchRequest(query: "Somebody", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotFindConversationsUsingPartialNames() {
        // given
        let resultArrived = expectation(description: "received result")
        _ = createGroupConversation(withName: "Somebody")

        let request = SearchRequest(query: "mebo", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsSeveralConversations() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation1 = createGroupConversation(withName: "Candy Apple Records")
        let conversation2 = createGroupConversation(withName: "Landspeed Records")
        _ = createGroupConversation(withName: "New Day Rising")

        let request = SearchRequest(query: "Records", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation1, conversation2])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatConversationSearchIsCaseInsensitive() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation = createGroupConversation(withName: "SoMEBody")

        let request = SearchRequest(query: "someBodY", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatConversationSearchIsInsensitiveToDiacritics() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation = createGroupConversation(withName: "Sömëbodÿ")

        let request = SearchRequest(query: "Sømebôdy", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItOnlyFindsGroupConversations() {
        // given
        let resultArrived = expectation(description: "received result")
        let groupConversation = createGroupConversation(withName: "Group Conversation")
        let oneOnOneConversation = createGroupConversation(withName: "OneOnOne Conversation")
        oneOnOneConversation.conversationType = .oneOnOne
        let selfConversation = createGroupConversation(withName: "Self Conversation")
        selfConversation.conversationType = .self

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Conversation", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [groupConversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsConversationsThatDoNotHaveAUserDefinedName() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let user1 = createConnectedUser(withName: "Shinji")
        let user2 = createConnectedUser(withName: "Asuka")
        let user3 = createConnectedUser(withName: "Rëï")

        conversation.addParticipantsAndUpdateConversationState(users: [user1, user2, user3], role: nil)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Rei", searchOptions: [.conversations, .contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
            XCTAssertEqual(result.contacts.compactMap(\.user), [user3])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsConversationsThatContainsSearchTermOnlyInParticipantName() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation = createGroupConversation(withName: "Summertime")
        let user = createConnectedUser(withName: "Rëï")
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Rei", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItOrdersConversationsByUserDefinedName() {
        // given
        let resultArrived = expectation(description: "received result")
        let conversation1 = createGroupConversation(withName: "FooA")
        let conversation2 = createGroupConversation(withName: "FooC")
        let conversation3 = createGroupConversation(withName: "FooB")

        let request = SearchRequest(query: "Foo", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation1, conversation3, conversation2])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItOrdersConversationsByUserDefinedNameFirstAndByParticipantNameSecond() {
        // given
        let resultArrived = expectation(description: "received result")
        let user1 = createConnectedUser(withName: "Bla")
        let user2 = createConnectedUser(withName: "FooB")

        let conversation1 = createGroupConversation(withName: "FooA")
        let conversation2 = createGroupConversation(withName: "Bar")
        let conversation3 = createGroupConversation(withName: "FooB")
        let conversation4 = createGroupConversation(withName: "Bar")

        conversation2.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation4.addParticipantsAndUpdateConversationState(users: [user1, user2], role: nil)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Foo", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation1, conversation3, conversation4])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFiltersConversationWhenTheQueryStartsWithAtSymbol() {
        // given
        let resultArrived = expectation(description: "received result")
        _ = createGroupConversation(withName: "New Day Rising")
        _ = createGroupConversation(withName: "Landspeed Records")

        let request = SearchRequest(query: "@records", searchOptions: [.conversations])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItReturnsAllConversationsWhenPassingTeamParameter() {
        // given
        let resultArrived = expectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let conversationInTeam = createGroupConversation(withName: "Beach Club")
        let conversationNotInTeam = createGroupConversation(withName: "Beach Club")

        conversationInTeam.team = team

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Beach", searchOptions: [.conversations], team: team)
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(Set(result.conversations), Set([conversationInTeam, conversationNotInTeam]))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Directory Search

    func testThatItSendsASearchRequest() {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/search/contacts?q=steve%20o'hara%20%26%20s%C3%B6hne&size=10")
    }

    func testThatItDoesNotSendASearchRequestIfSeachingLocally() {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 0)
    }

    func testThatItEncodesAPlusCharacterInTheSearchURL() {
        // given
        let request = SearchRequest(query: "foo+bar@example.com", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/search/contacts?q=foo%2Bbar&domain=example.com&size=10")
    }

    func testThatItEncodesUnsafeCharactersInRequest() {
        // RFC 3986 Section 3.4 "Query"
        // <https://tools.ietf.org/html/rfc3986#section-3.4>
        //
        // "The characters slash ("/") and question mark ("?") may represent data within the query component."

        // given
        let request = SearchRequest(query: "$&+,/:;=?@", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/search/contacts?q=$%26%2B,/:;%3D?&size=10")
    }

    func testThatItCallsCompletionHandlerForDirectorySearch() {
        // given
        let resultArrived = expectation(description: "received result")
        let request = SearchRequest(query: "User", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            remoteChanges.insertUser(withName: "User A")
        }

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.directory.first?.name, "User A")
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Directory Search - Membership lookup

    func testThatItMakesRequestToFetchTeamMembershipMetadata() {
        // given
        let request = SearchRequest(query: "User", searchOptions: [.directory, .teamMembers])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let userA = remoteChanges.insertUser(withName: "User A")
            let team = remoteChanges.insertTeam(withName: "Team A", isBound: true)
            team.identifier = self.teamIdentifier.transportString()
            team.creator = userA
            remoteChanges.insertMember(with: userA, in: team)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 2)
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/search/contacts?q=user&size=10")
        XCTAssertEqual(mockTransportSession.receivedRequests().last?.path, "/teams/\(teamIdentifier.transportString())/get-members-by-ids-using-post")
    }

    func testThatItCallsCompletionHandlerForTeamMemberDirectorySearch() {
        // given
        let resultArrived = expectation(description: "received result")
        let request = SearchRequest(query: "User", searchOptions: [.directory, .teamMembers])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let userA = remoteChanges.insertUser(withName: "User A")
            let selfUser = remoteChanges.insertSelfUser(withName: "Self User")
            let team = remoteChanges.insertTeam(withName: "Team A", isBound: true)
            team.identifier = self.teamIdentifier.transportString()
            team.creator = userA
            remoteChanges.insertMember(with: selfUser, in: team)
            let member = remoteChanges.insertMember(with: userA, in: team)
            member.permissions = .admin
        }

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.first?.name, "User A")
            XCTAssertEqual(result.teamMembers.first?.teamRole, .admin)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Services search

    func testThatItSendsASearchServicesRequest() {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.services])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performRemoteSearchForServices()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/teams/\(teamIdentifier.transportString())/services/whitelisted?prefix=steve%20o'hara%20%26%20s%C3%B6hne")
    }

    func testThatItCallsCompletionHandlerForServicesSearch() {
        // given
        let resultArrived = expectation(description: "received result")
        let request = SearchRequest(query: "Service", searchOptions: [.services])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            remoteChanges.insertService(withName: "Service A",
                                        identifier: UUID().transportString(),
                                        provider: UUID().transportString())
        }

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.services.first?.name, "Service A")
        }

        // when
        task.performRemoteSearchForServices()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItTrimsThePrefixQuery() throws {
        // when
        let task = SearchTask.servicesSearchRequest(teamIdentifier: self.teamIdentifier, query: "Search query ", apiVersion: .v0)
        // then
        let components = URLComponents(url: task.URL, resolvingAgainstBaseURL: false)

        XCTAssertEqual(components?.queryItems?.count, 1)
        let queryItem = components?.queryItems?.first
        XCTAssertEqual(queryItem?.name, "prefix")
        XCTAssertEqual(queryItem?.value, "Search query")
    }

    func testThatItDoesNotAddPrefixQueryIfItIsEmpty() {
        // when
        let task = SearchTask.servicesSearchRequest(teamIdentifier: self.teamIdentifier, query: "", apiVersion: .v0)
        // then
        let components = URLComponents(url: task.URL, resolvingAgainstBaseURL: false)

        XCTAssertNil(components?.queryItems)
    }

    // MARK: User lookup

    func testThatItSendsAUserLookupRequest() {
        // given
        let userId = UUID()
        let task = SearchTask(lookupUserId: userId, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performUserLookup()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/users/\(userId.transportString())")
    }

    func testThatItCallsCompletionHandlerForUserLookup() {
        // given
        let resultArrived = expectation(description: "received result")

        var userId: UUID!
        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let mockUser = remoteChanges.insertUser(withName: "User A")
            userId = UUID(uuidString: mockUser.identifier)!
        }
        let task = SearchTask(lookupUserId: userId, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.directory.first?.name, "User A")
        }

        // when
        task.performUserLookup()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Federated search

    func testThatItSendsAFederatedUserSearchRequest() throws {
        // given
        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = SearchTask(request: searchRequest, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let request = try XCTUnwrap(mockTransportSession.receivedRequests().first)
        XCTAssertEqual(request.method, .methodGET)
        XCTAssertEqual(request.path, "/search/contacts?q=john&domain=example.com&size=10")
    }

    func testThatItCallsCompletionHandlerForFederatedUserSearch_WhenUserExists() {
        // given
        let federatedDomain = "example.com"
        let resultArrived = expectation(description: "received result")

        mockTransportSession.federatedDomains = [federatedDomain]
        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let mockUser = remoteChanges.insertUser(withName: "John Doe")
            mockUser.handle = "john"
            mockUser.domain = federatedDomain
        }

        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = SearchTask(request: searchRequest,
                              searchContext: searchMOC,
                              contextProvider: coreDataStack!,
                              transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertEqual(result.directory.first?.name, "John Doe")
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallsCompletionHandlerForFederatedUserSearch_WhenUserDoesntExist() {
        // given
        let resultArrived = expectation(description: "received result")
        mockTransportSession.federatedDomains = ["example.com"]

        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = SearchTask(request: searchRequest,
                              searchContext: searchMOC,
                              contextProvider: coreDataStack!,
                              transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            resultArrived.fulfill()
            XCTAssertTrue(result.directory.isEmpty)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Combined results

    func testThatRemoteResultsIncludePreviousLocalResults() {
        // given
        let localResultArrived = expectation(description: "received local result")
        let user = createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            localResultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // given
        let remoteResultArrived = expectation(description: "received remote result")

        // expect
        task.onResult { (result, _) in
            remoteResultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatLocalResultsIncludePreviousRemoteResults() {
        // given
        let remoteResultArrived = expectation(description: "received remote result")
        _ = createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, _) in
            remoteResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // given
        let localResultArrived = expectation(description: "received local result")

        // expect
        task.onResult { (result, _) in
            localResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTaskIsCompletedAfterLocalResult() {
        // given
        let localResultArrived = expectation(description: "received local result")
        let user = createConnectedUser(withName: "userA")
        let request = SearchRequest(query: "user", searchOptions: [.contacts])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, completed) in
            localResultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
            XCTAssertTrue(completed)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTaskIsCompletedAfterRemoteResults() {
        // given
        let remoteResultArrived = expectation(description: "received remote result")
        mockTransportSession.performRemoteChanges { (remoteChanges) in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (result, completed) in
            remoteResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
            XCTAssertTrue(completed)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTaskIsCompletedOnlyAfterFinalResultArrives() {
        // given
        let intermediateResultArrived = expectation(description: "received intermediate result")
        let finalResultsArrived = expectation(description: "received final result")
        _ = createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { (remoteChanges) in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = SearchTask(request: request, searchContext: searchMOC, contextProvider: coreDataStack!, transportSession: mockTransportSession)

        // expect
        task.onResult { (_, completed) in
            if completed {
                finalResultsArrived.fulfill()
            } else {
                intermediateResultArrived.fulfill()
            }
        }

        // when
        task.start()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}
