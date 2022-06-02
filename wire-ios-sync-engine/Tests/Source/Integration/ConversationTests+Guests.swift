////
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

class ConversationTests_Guests: IntegrationTest {

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
        createTeamAndConversations()
    }

    func testThatItSendsRequestToChangeAccessMode() {
        // given
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertFalse(conversation.accessMode!.contains(.allowGuests))
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.setAllowGuests(true, in: self.userSession!) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(conversation.accessMode!.contains(.allowGuests))
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/access")
    }

    func testThatItSendsRequestToCreateTheLink() {
        // given
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.accessMode = ["code", "invite"]
            self.groupConversationWithWholeTeam.accessRoleV2 = ["team_member", "non_team_member", "guest", "service"]
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(conversation.accessMode, [.code, .invite])
        XCTAssertEqual(conversation.accessRoles, [.teamMember, .nonTeamMember, .guest, .service])
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.updateAccessAndCreateWirelessLink(in: self.userSession!) { result in
            switch result {
            case .success(let link):
                XCTAssertEqual(link, self.groupConversationWithWholeTeam.link)
            case .failure:
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/code")
        XCTAssertEqual(request.method, .methodPOST)
    }

    func testThatItSendsRequestToFetchTheGuestLinkStatus() {
        // given
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.guestLinkFeatureStatus = "enabled"
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.canGenerateGuestLink(in: self.userSession!) { result in
            switch result {
            case .success:
                XCTAssertEqual(self.groupConversationWithWholeTeam.guestLinkFeatureStatus, "enabled")
            case .failure:
                XCTFail()
            }
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/features/conversationGuestLinks")
        XCTAssertEqual(request.method, .methodGET)

    }

    func testThatItSendsRequestToFetchTheGuestLinkStatus_AndFailsWhenConversationIdIsMissing() {
        // GIVEN
        performIgnoringZMLogError {
            XCTAssert(self.login())
            var conversation: ZMConversation!
            self.mockTransportSession.performRemoteChanges { _ in
                conversation = self.conversation(for: self.groupConversationWithWholeTeam)!
            }

            conversation.remoteIdentifier = UUID.create()

            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.1))
            self.mockTransportSession?.resetReceivedRequests()

            // WHEN
            let didFail  = self.expectation(description: "did fail")
            conversation.canGenerateGuestLink(in: self.userSession!) { result in
                // THEN
                switch result {
                case .success:
                    XCTFail()
                case .failure(let error):
                    XCTAssertEqual(error as! WirelessLinkError, WirelessLinkError.noConversation)
                    didFail.fulfill()
                }
            }

            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.4))

        }
    }

    func testThatItSendsRequestToSetModeIfLegacyWhenFetchingTheLink() {
        // given
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.accessMode = ["invite"]
            self.groupConversationWithWholeTeam.accessRoleV2 = ["team_member", "non_team_member", "guest"]
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(conversation.accessMode, [.invite])
        XCTAssertEqual(conversation.accessRoles, [.teamMember, .nonTeamMember, .guest])
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.updateAccessAndCreateWirelessLink(in: self.userSession!) { result in
            switch result {
            case .success(let link):
                XCTAssertEqual(link, self.groupConversationWithWholeTeam.link)
            case .failure:
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 2)
        guard let requestFirst = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(requestFirst.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/access")
        guard let requestLast = mockTransportSession.receivedRequests().last else { return }
        XCTAssertEqual(requestLast.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/code")
        XCTAssertEqual(requestLast.method, .methodPOST)
    }

    func testThatItSendsRequestToFetchTheLink_NoLink() {
        // given
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.accessMode = ["code", "invite"]
            self.groupConversationWithWholeTeam.accessRoleV2 = ["team_member", "non_team_member", "guest", "service"]
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(conversation.accessMode, [.code, .invite])
        XCTAssertEqual(conversation.accessRoles, [.teamMember, .nonTeamMember, .guest, .service])
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.fetchWirelessLink(in: self.userSession!) { result in
            switch result {
            case .success(let link):
                XCTAssertNil(link)
            case .failure:
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/code")
        XCTAssertEqual(request.method, .methodGET)
    }

    func testThatItSendsRequestToFetchTheLink_LinkExists() {
        // given
        let existingLink = "https://wire-website.com/some-magic-link"

        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.accessMode = ["code", "invite"]
            self.groupConversationWithWholeTeam.accessRoleV2 = ["team_member", "non_team_member", "guest", "service"]
            self.groupConversationWithWholeTeam.link = existingLink
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(conversation.accessMode, [.code, .invite])
        XCTAssertEqual(conversation.accessRoles, [.teamMember, .nonTeamMember, .guest, .service])
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.fetchWirelessLink(in: self.userSession!) { result in
            switch result {
            case .success(let link):
                XCTAssertEqual(link, existingLink)
            case .failure:
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/code")
        XCTAssertEqual(request.method, .methodGET)
    }

    func testThatItSendsRequestToDeleteTheLink() {
        // given
        let existingLink = "https://wire-website.com/some-magic-link"

        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.accessMode = ["code", "invite"]
            self.groupConversationWithWholeTeam.accessRoleV2 = ["team_member", "non_team_member", "guest", "service"]
            self.groupConversationWithWholeTeam.link = existingLink
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertEqual(conversation.accessMode, [.code, .invite])
        XCTAssertEqual(conversation.accessRoles, [.teamMember, .nonTeamMember, .guest, .service])
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.deleteWirelessLink(in: self.userSession!) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/code")
        XCTAssertEqual(request.method, .methodDELETE)
    }

    func testThatItSendsRequestToDeleteTheLink_LinkDoesNotExist() {
        // given
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.accessMode = ["code", "invite"]
            self.groupConversationWithWholeTeam.accessRoleV2 = ["team_member", "non_team_member", "guest", "service"]
            self.groupConversationWithWholeTeam.link = nil
        }
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam)!

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation.accessMode, [.code, .invite])
        XCTAssertEqual(conversation.accessRoles, [.teamMember, .nonTeamMember, .guest, .service])
        mockTransportSession?.resetReceivedRequests()

        // when
        conversation.deleteWirelessLink(in: self.userSession!) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure:
                break
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 1)
        guard let request = mockTransportSession.receivedRequests().first else { return }
        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/code")
        XCTAssertEqual(request.method, .methodDELETE)
    }

    func testThatAccessModeChangeEventIsHandled() {
        // given
        XCTAssert(login())

        let conversation = self.conversation(for: self.groupConversationWithWholeTeam!)!
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertFalse(conversation.accessMode!.contains(.allowGuests))

        // when
        mockTransportSession?.performRemoteChanges { _ in
            self.groupConversationWithWholeTeam.set(allowGuests: true, allowServices: true)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(conversation.accessMode!.contains(.allowGuests))
    }

}
