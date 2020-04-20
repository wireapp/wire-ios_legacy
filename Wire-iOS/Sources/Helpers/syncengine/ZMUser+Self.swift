//
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
import WireDataModel
import WireSyncEngine

typealias EditableUser = UserType & ZMEditableUser & SelfLegalHoldSubject & ValidatorType

protocol SelfUserProviderUI {
    static var selfUser: EditableUser { get }
}

extension ZMUser {

    /// Return self's User object
    ///
    /// - Returns: a ZMUser<ZMEditableUser> object for app target, or a MockUser object for test.
    static func selfUser() -> EditableUser! {

        if let mockUserClass = NSClassFromString("MockUser") as? SelfUserProviderUI.Type {
            return mockUserClass.selfUser
        } else {
            guard let session = ZMUserSession.shared() else { return nil }

            return ZMUser.selfUser(inUserSession: session)
        }
    }
}


//TODO: move to DM
extension UserType {
    var remoteIdentifier: UUID? {
        return (self as? ZMUser)?.remoteIdentifier
    }
    
    var hasTeam: Bool! {
        return (self as? ZMUser)?.hasTeam
    }

    var team: Team? {
        return (self as? ZMUser)?.team
    }
    
    var clients: [UserClient]! {
        return (self as? ZMUser)?.clients
    }

    var clientsRequiringUserAttention: [UserClient]! {
        return (self as? ZMUser)?.clientsRequiringUserAttention
    }

    
    func filename(suffix: String? = nil) -> String! {
        return (self as? ZMUser)?.filename(suffix: suffix)
    }
    
    func fetchMarketingConsent(in userSession: ZMUserSession,
                                      completion: @escaping ((Result<Bool>) -> Void)) {
        (self as? ZMUser)?.fetchMarketingConsent(in: userSession, completion: completion)
    }

    var needsToNotifyAvailabilityBehaviourChange: NotificationMethod! {
        get {
            return (self as? ZMUser)?.needsToNotifyAvailabilityBehaviourChange
        }
        set {
            (self as? ZMUser)?.needsToNotifyAvailabilityBehaviourChange = newValue
        }
    }
    
    func setMarketingConsent(to value: Bool,
                                    in userSession: ZMUserSession,
                                    completion: @escaping ((VoidResult) -> Void)) {
        (self as? ZMUser)?.setMarketingConsent(to: value, in: userSession, completion: completion)
    }

    var previewImageData: Data? {
        return (self as? ZMUser)?.previewImageData
    }

    var imageSmallProfileData: Data! {
        return (self as? ZMUser)?.imageSmallProfileData
    }
    
    var imageMediumData: Data? {
        return (self as? ZMUser)?.imageMediumData
    }
    
        
    var hasValidEmail: Bool! {
        return (self as? ZMUser)?.hasValidEmail
    }

    var canSeeServices: Bool! {
        return (self as? ZMUser)?.canSeeServices
    }

    
    var readReceiptsEnabledChangedRemotely: Bool! {
        get {
        return (self as? ZMUser)?.readReceiptsEnabledChangedRemotely
        }
        
        set {
            (self as? ZMUser)?.readReceiptsEnabledChangedRemotely = newValue
        }
    }
    
    func selfClient() -> UserClient? {
        return (self as? ZMUser)?.selfClient()
    }
    
    
}
