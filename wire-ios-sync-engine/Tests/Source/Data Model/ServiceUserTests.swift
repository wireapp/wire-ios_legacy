//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

@testable import WireSyncEngine

final class DummyServiceUser: NSObject, ServiceUser {

    func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {

    }

    func connect(completion: @escaping (Error?) -> Void) {

    }

    func block(completion: @escaping (Error?) -> Void) {

    }

    func accept(completion: @escaping (Error?) -> Void) {

    }

    func ignore(completion: @escaping (Error?) -> Void) {

    }

    var remoteIdentifier: UUID?

    var isIgnored: Bool = false

    var hasTeam: Bool = false

    var isTrusted: Bool = false

    var hasLegalHoldRequest: Bool = false

    var needsRichProfileUpdate: Bool = false

    var availability: AvailabilityKind = .none

    var teamName: String?

    var isBlocked: Bool = false

    var blockState: ZMBlockState = .none

    var isExpired: Bool = false

    var isPendingApprovalBySelfUser: Bool = false

    var isPendingApprovalByOtherUser: Bool = false

    var isWirelessUser: Bool = false

    var isUnderLegalHold: Bool = false

    var allClients: [UserClientType]  = []

    var expiresAfter: TimeInterval = 0

    var readReceiptsEnabled: Bool = true

    var isVerified: Bool = false

    var richProfile: [UserRichProfileField] = []

    /// Whether the user can create conversations.
    @objc
    func canCreateConversation(type: ZMConversationType) -> Bool {
        return true
    }

    var canCreateService: Bool = false

    var canManageTeam: Bool = false

    func canAccessCompanyInformation(of user: UserType) -> Bool {
        return false
    }

    func canAddUser(to conversation: ConversationLike) -> Bool {
        return false
    }

    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        return false
    }

    func canAddService(to conversation: ZMConversation) -> Bool {
        return false
    }

    func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        return false
    }

    func canRemoveService(from conversation: ZMConversation) -> Bool {
        return false
    }

    func canModifyReadReceiptSettings(in conversation: ConversationLike) -> Bool {
        return false
    }

    func canModifyEphemeralSettings(in conversation: ConversationLike) -> Bool {
        return false
    }

    func canModifyNotificationSettings(in conversation: ConversationLike) -> Bool {
        return false
    }

    func canModifyAccessControlSettings(in conversation: ConversationLike) -> Bool {
        return false
    }

    func canModifyTitle(in conversation: ConversationLike) -> Bool {
        return false
    }

    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        return false
    }

    func canLeave(_ conversation: ZMConversation) -> Bool {
        return false
    }

    func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        return false
    }

    var domain: String?

    var previewImageData: Data?

    var completeImageData: Data?

    var name: String? = "Service user"

    var displayName: String = "Service"

    var initials: String? = "S"

    var handle: String? = "service"

    var emailAddress: String? = "dummy@email.com"

    var phoneNumber: String?

    var isSelfUser: Bool = false

    var smallProfileImageCacheKey: String? = ""

    var mediumProfileImageCacheKey: String? = ""

    var isConnected: Bool = false

    var oneToOneConversation: ZMConversation?

    var accentColorValue: ZMAccentColor = ZMAccentColor.brightOrange

    var imageMediumData: Data! = Data()

    var imageSmallProfileData: Data! = Data()

    var imageSmallProfileIdentifier: String! = ""

    var imageMediumIdentifier: String! = ""

    var isTeamMember: Bool = false

    var hasDigitalSignatureEnabled: Bool = false

    var teamRole: TeamRole = .member

    var canBeConnected: Bool = false

    var isServiceUser: Bool = true

    var isFederated: Bool = false

    var usesCompanyLogin: Bool = false

    var isAccountDeleted: Bool = false

    var managedByWire: Bool = true

    var extendedMetadata: [[String: String]]?

    var activeConversations: Set<ZMConversation> = Set()

    func requestPreviewProfileImage() {

    }

    func requestCompleteProfileImage() {

    }

    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {

    }

    func refreshData() {

    }

    func refreshRichProfile() {

    }

    func refreshMembership() {

    }

    func refreshTeamData() {

    }

    func isGuest(in conversation: ConversationLike) -> Bool {
        return false
    }

    var connectionRequestMessage: String? = ""

    var totalCommonConnections: UInt = 0

    var serviceIdentifier: String?
    var providerIdentifier: String?

    init(serviceIdentifier: String, providerIdentifier: String) {
        self.serviceIdentifier = serviceIdentifier
        self.providerIdentifier = providerIdentifier
        super.init()
    }

}

final class ServiceUserTests: IntegrationTest {
    public override func setUp() {
        super.setUp()
        self.createSelfUserAndConversation()
        self.createExtraUsersAndConversations()

        XCTAssertTrue(self.login())
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func createService() -> ServiceUser {
        var mockServiceId: String!
        var mockProviderId: String!
        mockTransportSession.performRemoteChanges { (remoteChanges) in
            let mockService = remoteChanges.insertService(withName: "Service A",
                                                          identifier: UUID().transportString(),
                                                          provider: UUID().transportString())

            mockServiceId = mockService.identifier
            mockProviderId = mockService.provider
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return DummyServiceUser(serviceIdentifier: mockServiceId, providerIdentifier: mockProviderId)
    }

    func testThatItAddsServiceToExistingConversation() throws {
        // given
        let jobIsDone = expectation(description: "service is added")
        let service = self.createService()
        let conversation = self.conversation(for: self.groupConversation)!

        // when
        conversation.add(serviceUser: service, in: userSession!) { (result) in
            XCTAssertNil(result.error)
            jobIsDone.fulfill()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCreatesConversationAndAddsUser() {
        // given
        let jobIsDone = expectation(description: "service is added")
        let service = self.createService()

        // when
        service.createConversation(in: userSession!) { (result) in
            XCTAssertNotNil(result.value)
            jobIsDone.fulfill()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDetectsTheConversationFullResponse() {
        // GIVEN
        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .tooManyParticipants)
    }

    func testThatItDetectsBotRejectedResponse() {
        // GIVEN
        let response = ZMTransportResponse(payload: nil, httpStatus: 419, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .botRejected)
    }

    func testThatItDetectsBotNotResponding() {
        // GIVEN
        let response = ZMTransportResponse(payload: nil, httpStatus: 502, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .botNotResponding)
    }

    func testThatItDetectsGeneralError() {
        // GIVEN
        let response = ZMTransportResponse(payload: nil, httpStatus: 500, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .general)
    }
}
