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
@testable import Wire

class MockUserType: NSObject, UserType, Decodable {

    // MARK: - Decodable

    required convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        initials = try? container.decode(String.self, forKey: .initials)
        handle = try? container.decode(String.self, forKey: .handle)
        isConnected = (try? container.decode(Bool.self, forKey: .isConnected)) ?? false
        connectionRequestMessage = try? container.decode(String.self, forKey: .connectionRequestMessage)

        if let rawAccentColorValue = try? container.decode(Int16.self, forKey: .accentColorValue),
           let accentColorValue = ZMAccentColor(rawValue: rawAccentColorValue)
        {
            self.accentColorValue = accentColorValue
        }
    }

    enum CodingKeys: String, CodingKey {

        case name
        case displayName
        case initials
        case handle
        case isConnected
        case accentColorValue
        case connectionRequestMessage

    }

    // MARK: - MockHelpers

    private let legalHoldDataSource = MockLegalHoldDataSource()
    private var teamIdentifier: UUID?

    // MARK: - Basic Properties

    var name: String? = nil

    var displayName: String = ""

    var initials: String? = nil

    var handle: String? = nil

    var emailAddress: String? = nil

    var accentColorValue: ZMAccentColor = .strongBlue

    var availability: Availability = .available

    var allClients: [UserClientType] = []

    var smallProfileImageCacheKey: String? = nil

    var mediumProfileImageCacheKey: String? = nil

    var previewImageData: Data? = nil

    var completeImageData: Data? = nil

    var richProfile: [UserRichProfileField] = []

    var readReceiptsEnabled: Bool = false

    // MARK: - Conversations

    var oneToOneConversation: ZMConversation? = nil

    var activeConversations: Set<ZMConversation> = Set()

    // MARK: - Querying

    var isSelfUser: Bool = false

    var isServiceUser: Bool = false

    var isVerified: Bool = false

    // MARK: - Team

    var isTeamMember: Bool {
        return teamIdentifier != nil
    }

    var teamName: String? = nil

    var teamRole: TeamRole = .none

    // MARK: - Connections

    var connectionRequestMessage: String? = nil

    var canBeConnected: Bool = false

    var isConnected: Bool = false

    var isBlocked: Bool = false

    var isPendingApprovalBySelfUser: Bool = false

    var isPendingApprovalByOtherUser: Bool = false

    // MARK: - Wireless

    var isWirelessUser: Bool = false

    var isExpired: Bool = false

    var expiresAfter: TimeInterval = 0

    // MARK: - Other

    var usesCompanyLogin: Bool = false

    var managedByWire: Bool = false

    var isAccountDeleted: Bool = false

    var isUnderLegalHold: Bool = false

    var shouldHideAvailability: Bool = false

    var needsRichProfileUpdate: Bool = false

    // MARK: - Capabilities

    var canCreateService: Bool = false

    var canManageTeam: Bool = false

    var canLeaveConversation: Bool = false

    func canLeave(_ conversation: ZMConversation) -> Bool {
        return canLeaveConversation
    }

    var canCreateConversation: Bool = false

    func canCreateConversation(type: ZMConversationType) -> Bool {
        return canCreateConversation
    }

    var canDeleteConversation: Bool = false

    func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        return canDeleteConversation
    }

    var canAddUserToConversation: Bool = false

    func canAddUser(to conversation: ZMConversation) -> Bool {
        return canAddUserToConversation
    }

    var canRemoveUserFromConversation: Bool = false

    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        return canRemoveUserFromConversation
    }

    var canAddServiceToConversation: Bool = false

    func canAddService(to conversation: ZMConversation) -> Bool {
        return canAddServiceToConversation
    }

    func canRemoveService(from conversation: ZMConversation) -> Bool {
        // TODO: This looks wrong, investigate.
        return canRemoveUserFromConversation
    }

    func canAccessCompanyInformation(of user: UserType) -> Bool {
        fatalError()
    }

    var canModifyOtherMemberInConversation: Bool = false

    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        return canModifyOtherMemberInConversation
    }

    var canModifyTitleInConversation: Bool = false

    func canModifyTitle(in conversation: ZMConversation) -> Bool {
        return canModifyTitleInConversation
    }

    var canModifyReadReceiptSettingsInConversation: Bool = false

    func canModifyReadReceiptSettings(in conversation: ZMConversation) -> Bool {
        return canModifyReadReceiptSettingsInConversation
    }

    var canModifyEphemeralSettingsInConversation: Bool = false

    func canModifyEphemeralSettings(in conversation: ZMConversation) -> Bool {
        return canModifyEphemeralSettingsInConversation
    }

    var canModifyNotificationSettingsInConversation: Bool = false

    func canModifyNotificationSettings(in conversation: ZMConversation) -> Bool {
        return canModifyNotificationSettingsInConversation
    }

    func canModifyAccessControlSettings(in conversation: ZMConversation) -> Bool {
        // TODO: This looks wrong, investigate.
        return canModifyNotificationSettingsInConversation
    }

    var isGroupAdminInConversation: Bool = false

    func isGroupAdmin(in conversation: ZMConversation) -> Bool {
        return isGroupAdminInConversation
    }

    // MARK: - Methods

    func connect(message: String) {
        // No op
    }

    var isGuestInConversation: Bool = false

    func isGuest(in conversation: ZMConversation) -> Bool {
        return isGuestInConversation
    }

    func requestPreviewProfileImage() {
        // No op
    }

    func requestCompleteProfileImage() {
        // No op
    }

    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        switch size {
        case .preview:
            completion(previewImageData)
        case .complete:
            completion(completeImageData)
        }
    }

    func refreshData() {
        // No op
    }

}

// MARK: - Profile Image

extension MockUserType: ProfileImageFetchable {

    func fetchProfileImage(session: ZMUserSessionInterface,
                           cache: ImageCache<UIImage> = defaultUserImageCache,
                           sizeLimit: Int? = nil,
                           desaturate: Bool = false,
                           completion: @escaping (UIImage?, Bool) -> Void) {

        let image = completeImageData.flatMap(UIImage.init)
        completion(image, false)
    }
}

extension MockUserType {

    /// Creates a self-user with the specified name and team membership.
    ///
    /// - Parameters:
    ///   - name: The name of the user.
    ///   - teamID: The ID of the team of the user, or `nil` if they're not on a team.
    ///
    /// - Returns: A configured mock user object to use as a self-user.

    class func createSelfUser(name: String, inTeam teamID: UUID?) -> MockUserType {
        let user = createUser(name: name, inTeam: teamID)
        user.isSelfUser = true
        user.accentColorValue = .vividRed
        return user
    }

    /// Creates a connected user with the specified name and team membership.
    ///
    /// - Parameters:
    ///   - name: The name of the user.
    ///   - teamID: The ID of the team of the user, or `nil` if they're not on a team.
    ///
    /// - Returns: A configured mock user object to use as a user the self-user can interact with.

    class func createConnectedUser(name: String, inTeam teamID: UUID?) -> MockUserType {
        let user = createUser(name: name, inTeam: teamID)
        user.isSelfUser = false
        user.isConnected = true
        user.accentColorValue = .brightOrange
        return user
    }

    private class func createUser(name: String, inTeam teamID: UUID?) -> MockUserType {
        let user = MockUserType()
        user.name = name
        user.displayName = name
        user.initials = PersonName.person(withName: name, schemeTagger: nil).initials
        user.emailAddress = teamID != nil ? "test@email.com" : nil
        user.teamIdentifier = teamID
        user.teamRole = teamID != nil ? .member : .none
        // user.remoteIdentifier = UUID() Do we need this?
        return user
    }

}

extension MockUserType: SelfLegalHoldSubject {

    var legalHoldStatus: UserLegalHoldStatus {
        if isUnderLegalHold {
            return .enabled
        } else if let request = legalHoldDataSource.legalHoldRequest {
            return .pending(request)
        } else {
            return .disabled
        }
    }

    var needsToAcknowledgeLegalHoldStatus: Bool {
        return legalHoldDataSource.needsToAcknowledgeLegalHoldStatus
    }

    func legalHoldRequestWasCancelled() {
        legalHoldDataSource.legalHoldRequest = nil
    }

    func userDidReceiveLegalHoldRequest(_ request: LegalHoldRequest) {
        legalHoldDataSource.legalHoldRequest = request
    }

    func userDidAcceptLegalHoldRequest(_ request: LegalHoldRequest) {
        legalHoldDataSource.legalHoldRequest = nil
        isUnderLegalHold = true
    }

    func acknowledgeLegalHoldStatus() {
        legalHoldDataSource.needsToAcknowledgeLegalHoldStatus = false
    }

    func requestLegalHold() {
        let keyData = Data(base64Encoded: "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g==")!
        let prekey = LegalHoldRequest.Prekey(id: 65535, key: keyData)

        legalHoldDataSource.legalHoldRequest = LegalHoldRequest(target: UUID(),
                                                                requester: UUID(),
                                                                clientIdentifier: "eca3c87cfe28be49",
                                                                lastPrekey: prekey)
    }

}
