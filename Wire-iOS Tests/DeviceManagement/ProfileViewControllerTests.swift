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

import XCTest
@testable import Wire

final class ProfileViewControllerTests: ZMSnapshotTestCase {

    var sut: ProfileViewController!
    var mockUser: MockUser!
    var selfUser: MockUser!
    var teamIdentifier: UUID!
    
    override func setUp() {
        super.setUp()
        teamIdentifier = UUID()
        selfUser = MockUser.createSelfUser(name: "George Johnson", inTeam: teamIdentifier)
        selfUser.handle = "georgejohnson"
        selfUser.feature(withUserClients: 6)

        mockUser = MockUser.createConnectedUser(name: "Catherine Jackson", inTeam: teamIdentifier)
        mockUser.handle = "catherinejackson"
        mockUser.feature(withUserClients: 6)
    }
    
    override func tearDown() {
        sut = nil
        mockUser = nil
        selfUser = nil
        teamIdentifier = nil

        super.tearDown()
    }

    func testForContextProfileViewer() {
        selfUser.teamRole = .member
        mockUser.emailAddress = nil
        sut = ProfileViewController(user: mockUser,
                                    viewer: selfUser,
                                    context: .profileViewer)

        verify(view: sut.view)
    }

    func testForContextProfileViewerForSelfUser() {
        selfUser.teamRole = .member
        selfUser.emailAddress = nil
        sut = ProfileViewController(user: selfUser,
                                    viewer: selfUser,
                                    context: .profileViewer)

        verify(view: sut.view)
    }

    func testForContextOneToOneConversation() {
        selfUser.teamRole = .member
        mockUser.emailAddress = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        sut = ProfileViewController(user: mockUser, viewer: selfUser,
                                    conversation: conversation.convertToRegularConversation(), context: .oneToOneConversation)

        self.verify(view: sut.view)
    }

    func testForContextOneToOneConversationForPartnerRole() {
        selfUser.teamRole = .partner
        mockUser.emailAddress = nil

        let conversation = MockConversation.oneOnOneConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        sut = ProfileViewController(user: mockUser, viewer: selfUser,
                                    conversation: conversation.convertToRegularConversation(), context: .oneToOneConversation)

        self.verify(view: sut.view)
    }

    func testForDeviceListContext() {
        sut = ProfileViewController(user: mockUser, viewer: selfUser, context: .deviceList)
        self.verify(view: sut.view)
    }


    func testForIncomingRequest() {
        // GIVEN
        mockUser.isConnected = false
        mockUser.canBeConnected = true
        mockUser.isPendingApprovalBySelfUser = true
        mockUser.emailAddress = nil

        let conversation = MockConversation.groupConversation()
        conversation.activeParticipants = [selfUser, mockUser]

        // WHEN
        sut = ProfileViewController(user: mockUser, viewer: selfUser,
                                    conversation: conversation.convertToRegularConversation(), context: .groupConversation)

        // THEN
        verify(view: sut.view)
    }

    func testForWrapInNavigationController() {
        sut = ProfileViewController(user: mockUser, viewer: selfUser, context: .deviceList)
        let navWrapperController = sut.wrapInNavigationController()

        self.verify(view: navWrapperController.view)
    }
    
    func testForContextProfileViewerUnderLegalHold() {
        selfUser.teamRole = .member
        mockUser.emailAddress = nil
        mockUser.isUnderLegalHold = true
        sut = ProfileViewController(user: mockUser,
                                    viewer: selfUser,
                                    context: .profileViewer)
        let navWrapperController = sut.wrapInNavigationController()
        
        verify(view: navWrapperController.view)
    }
    
    func testForContextProfileViewerUnderLegalHold_WithSelfUserOutsideTeam() {
        let selfUserOutsideTeam = MockUser.createSelfUser(name: "John Johnson", inTeam: nil)
        selfUserOutsideTeam.handle = "johnjohnson"
        selfUserOutsideTeam.feature(withUserClients: 6)
        
        mockUser.emailAddress = nil
        mockUser.isUnderLegalHold = true
        sut = ProfileViewController(user: mockUser,
                                    viewer: selfUserOutsideTeam,
                                    context: .profileViewer)
        let navWrapperController = sut.wrapInNavigationController()
        
        verify(view: navWrapperController.view)
    }
    
    
    func testForContextProfileViewerForSelfUserUnderLegalHold() {
        selfUser.teamRole = .member
        selfUser.emailAddress = nil
        selfUser.isUnderLegalHold = true
        sut = ProfileViewController(user: selfUser,
                                    viewer: selfUser,
                                    context: .profileViewer)
        let navWrapperController = sut.wrapInNavigationController()
        
        verify(view: navWrapperController.view)
    }

}
