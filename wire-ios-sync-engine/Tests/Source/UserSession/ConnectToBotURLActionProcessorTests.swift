//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class ConnectToBotURLActionProcessorTests: IntegrationTest {

    let serviceName = "Service ABC"
    let serviceIdentifier = UUID()
    let serviceProvider = UUID()

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()

        mockTransportSession.performRemoteChanges { (session) in
            session.insertService(withName: self.serviceName,
                                  identifier: self.serviceIdentifier.transportString(),
                                  provider: self.serviceProvider.transportString())
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatCompletedURLActionIsCalled_WhenSuccessfullyConnectingToAService() {
        // given
        XCTAssertTrue(login())

        let presentationDelegate = MockPresentationDelegate()
        let action = URLAction.connectBot(serviceUser: ServiceUserData(provider: serviceProvider, service: serviceIdentifier))
        let sut = WireSyncEngine.ConnectToBotURLActionProcessor(contextprovider: userSession!,
                                                                transportSession: mockTransportSession,
                                                                eventProcessor: userSession!.updateEventProcessor!)

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(presentationDelegate.completedURLActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.completedURLActionCalls.first, action)
    }

    func testThatFailedToPerformActionIsCalled_WhenFailingToConnectToService() {
        // given
        XCTAssertTrue(login())

        let unknownService = ServiceUserData(provider: UUID(), service: UUID())
        let presentationDelegate = MockPresentationDelegate()
        let action = URLAction.connectBot(serviceUser: unknownService)
        let sut = WireSyncEngine.ConnectToBotURLActionProcessor(contextprovider: userSession!,
                                                                transportSession: mockTransportSession,
                                                                eventProcessor: userSession!.updateEventProcessor!)

        // when
        sut.process(urlAction: action, delegate: presentationDelegate)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.1 as? AddBotError, AddBotError.general)
    }

}
