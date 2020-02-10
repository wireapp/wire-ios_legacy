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

class MockUserType: NSObject, UserType, Mockable {

    required init!(jsonObject: [AnyHashable : Any]!) {
        fatalError()
    }

    // MARK: - Basic Properties

    var displayName: String = ""

    var name: String? = nil

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

    var isTeamMember: Bool = false

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

    func canCreateConversation(type: ZMConversationType) -> Bool {
        fatalError()
    }

    func canAccessCompanyInformation(of user: UserType) -> Bool {
        fatalError()
    }

    func canAddService(to conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canRemoveService(from conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canAddUser(to conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canModifyReadReceiptSettings(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canModifyEphemeralSettings(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canModifyNotificationSettings(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canModifyAccessControlSettings(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canModifyTitle(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func canLeave(_ conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func isGroupAdmin(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    // MARK: - Methods

    func connect(message: String) {
        fatalError()
    }

    func isGuest(in conversation: ZMConversation) -> Bool {
        fatalError()
    }

    func requestPreviewProfileImage() {
        fatalError()
    }

    func requestCompleteProfileImage() {
        fatalError()
    }

    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        fatalError()
    }

    func refreshData() {
        fatalError()
    }

}
