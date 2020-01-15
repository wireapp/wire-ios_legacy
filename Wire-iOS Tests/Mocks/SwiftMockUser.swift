
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class MockSelfUser: SwiftMockUser, SelfLegalHoldSubject {

    var legalHoldStatus: UserLegalHoldStatus = .enabled
    
    var needsToAcknowledgeLegalHoldStatus: Bool = true
    
    func legalHoldRequestWasCancelled() {
        
    }
    
    func userDidReceiveLegalHoldRequest(_ request: LegalHoldRequest) {
        
    }
    
    func userDidAcceptLegalHoldRequest(_ request: LegalHoldRequest) {
        
    }
    
    func acknowledgeLegalHoldStatus() {
        
    }
}

/// a new simple Mock User without objc
class SwiftMockUser: NSObject, UserType {
    var name: String? = nil
    
    var displayName: String = ""
    
    var handle: String? = nil
    
    var initials: String? = nil
    
    var emailAddress: String? = nil
    
    var isSelfUser: Bool = true
    
    var availability: Availability = Availability(rawValue: 0)!
    
    var shouldHideAvailability: Bool = true
    
    var teamName: String? = nil
    
    var isTeamMember: Bool = true
    
    var teamRole: TeamRole = TeamRole.admin
    
    var isServiceUser: Bool = false
    
    var usesCompanyLogin: Bool = false
    
    var isConnected: Bool = true
    
    var oneToOneConversation: ZMConversation? = nil
    
    var isBlocked: Bool = false
    
    var isExpired: Bool = false
    
    var isPendingApprovalBySelfUser: Bool = false
    
    var isPendingApprovalByOtherUser: Bool  = false
    
    var canBeConnected: Bool = true
    
    var isAccountDeleted: Bool = false
    
    var isUnderLegalHold: Bool = false
    
    var accentColorValue: ZMAccentColor = ZMAccentColor(rawValue: 0)!
    
    var isWirelessUser: Bool = false
    
    var expiresAfter: TimeInterval = 0
    
    var connectionRequestMessage: String? = nil
    
    var smallProfileImageCacheKey: String? = nil
    
    var mediumProfileImageCacheKey: String? = nil
    
    var previewImageData: Data? = nil
    
    var completeImageData: Data? = nil
    
    var readReceiptsEnabled: Bool = false
    
    var richProfile: [UserRichProfileField] = []
    
    var needsRichProfileUpdate: Bool = false
    
    var activeConversations: Set<ZMConversation> = []
    
    var allClients: [UserClientType] = []
    
    func requestPreviewProfileImage() {
        
    }
    
    func requestCompleteProfileImage() {
        
    }
    
    var isGuestInConversation: Bool = false {
        didSet {
            if isGuestInConversation {
                isTeamMember = false
            }
        }
    }
    
    func isGuest(in conversation: ZMConversation) -> Bool {
        return isGuestInConversation
    }
    
    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        
    }
    
    func refreshData() {
        
    }
    
    func connect(message: String) {
        
    }
    
    var managedByWire: Bool = false
    
    var canCreateConversation: Bool = true
    
    func canCreateConversation(type: ZMConversationType) -> Bool {
        return canCreateConversation
    }
    
    var canCreateService: Bool = true
    
    var canManageTeam: Bool = true
    
    var canAccessCompanyInformation: Bool = true
    func canAccessCompanyInformation(of user: UserType) -> Bool {
        return canAccessCompanyInformation
    }
    
    func canAddService(to conversation: ZMConversation) -> Bool {
        return true
    }
    
    var canRemoveService = true
    func canRemoveService(from conversation: ZMConversation) -> Bool {
        return canRemoveService
    }
    
    func canAddUser(to conversation: ZMConversation) -> Bool {
        return true
    }
    
    var canRemoveUserFromConversation: Bool = true
    
    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        return canRemoveUserFromConversation
    }
    
    func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        return true
    }

    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
      return true
    }
    
    func canModifyReadReceiptSettings(in conversation: ZMConversation) -> Bool {
        return true
    }
    
    func canModifyEphemeralSettings(in conversation: ZMConversation) -> Bool {
        return true
    }
    
    func canModifyNotificationSettings(in conversation: ZMConversation) -> Bool {
        return true
    }
    
    func canModifyAccessControlSettings(in conversation: ZMConversation) -> Bool {
        return true
    }
    
    func canModifyTitle(in conversation: ZMConversation) -> Bool {
        return true
    }

    func canLeave(_ conversation: ZMConversation) -> Bool {
        return true
    }
    
    func isGroupAdmin(in conversation: ZMConversation) -> Bool {
        return true
    }
}
