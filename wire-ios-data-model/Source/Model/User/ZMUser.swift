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

import Foundation
import WireUtilities
import WireSystem

extension ZMUser: UserType {
    @objc
    public var hasTeam: Bool {
        /// Other users won't have a team object, but a teamIdentifier.
        return nil != team || nil != teamIdentifier
    }

    /// Whether all user's devices are verified by the selfUser
    public var isTrusted: Bool {
        let selfUser = managedObjectContext.map(ZMUser.selfUser)
        let selfClient = selfUser?.selfClient()
        let hasUntrustedClients = self.clients.contains(where: { ($0 != selfClient) && !(selfClient?.trustedClients.contains($0) ?? false) })

        return !hasUntrustedClients
    }

    public func isGuest(in conversation: ConversationLike) -> Bool {
        return _isGuest(in: conversation)
    }

    public var teamName: String? {
        return team?.name
    }

    public var hasDigitalSignatureEnabled: Bool {
        guard let context = managedObjectContext else { return false }
        let service = FeatureService(context: context)
        return service.fetchDigitalSignature().status == .enabled
    }

    public var previewImageData: Data? {
        return imageSmallProfileData
    }

    public var completeImageData: Data? {
        return imageMediumData
    }

    public var activeConversations: Set<ZMConversation> {
        return Set(self.participantRoles.compactMap {$0.conversation})
    }

    public var isVerified: Bool {
        guard let selfUser = managedObjectContext.map(ZMUser.selfUser) else {
            return false
        }
        return isTrusted && selfUser.isTrusted && !clients.isEmpty
    }

    public var isFederated: Bool {
        guard let selfUser = managedObjectContext.map(ZMUser.selfUser) else {
            return false
        }

        return selfUser.isFederating(with: self)
    }

    // MARK: - Conversation Roles

    public func canManagedGroupRole(of user: UserType, conversation: ZMConversation) -> Bool {
        guard isGroupAdmin(in: conversation) else { return false }
        return !user.isSelfUser && (user.isConnected || isOnSameTeam(otherUser: user))
    }

    public func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        return role(in: conversation)?.name == ZMConversation.defaultAdminRoleName
    }

    public func role(in conversation: ConversationLike?) -> Role? {
        return participantRoles.first(where: { $0.conversation === conversation })?.role
    }

    // MARK: Legal Hold

    @objc public var isUnderLegalHold: Bool {
        return clients.any(\.isLegalHoldDevice)
    }

    @objc class func keyPathsForValuesAffectingIsUnderLegalHold() -> Set<String> {
        return [UserClientsKey, "clients.deviceClass"]
    }

    public var allClients: [UserClientType] {
        return Array(clients)
    }

    // MARK: - Data refresh requests

    public func refreshRichProfile() {
        needsRichProfileUpdate = true
    }

    public func refreshMembership() {
        membership?.needsToBeUpdatedFromBackend = true
    }

    public func refreshTeamData() {
        team?.refreshMetadata()
    }

}

public struct AssetKey {

    static let legalCharacterSet = CharacterSet.alphanumerics.union(CharacterSet.punctuationCharacters)

    public init?(_ string: String) {
        if AssetKey.validate(string: string) {
            stringValue = string
        } else {
            return nil
        }
    }

    let stringValue: String

    fileprivate static func validate(string: String) -> Bool {
        return CharacterSet(charactersIn: string).isSubset(of: legalCharacterSet)
    }
}

@objc public enum ProfileImageSize: Int {
    case preview
    case complete

    public var imageFormat: ZMImageFormat {
        switch self {
        case .preview:
            return .profile
        case .complete:
            return .medium
        }
    }

    public init?(stringValue: String) {
        switch stringValue {
        case ProfileImageSize.preview.stringValue: self = .preview
        case ProfileImageSize.complete.stringValue: self = .complete
        default: return nil
        }
    }

    var stringValue: String {
        switch self {
        case .preview: return "preview"
        case .complete: return "complete"
        }
    }

    public static var allSizes: [ProfileImageSize] {
        return [.preview, .complete]
    }
}

extension ProfileImageSize: CustomDebugStringConvertible {
     public var debugDescription: String {
        switch self {
        case .preview:
            return "ProfileImageSize.preview"
        case .complete:
            return "ProfileImageSize.complete"
        }
    }
}

extension ZMUser: ServiceUser {
    @NSManaged public var providerIdentifier: String?
    @NSManaged public var serviceIdentifier: String?
}

public extension Notification.Name {
    static let userDidRequestPreviewAsset = Notification.Name("UserDidRequestPreviewAsset")
    static let userDidRequestCompleteAsset = Notification.Name("UserDidRequestCompleteAsset")
}

extension ZMUser {

    @objc static public let previewProfileAssetIdentifierKey = #keyPath(ZMUser.previewProfileAssetIdentifier)
    @objc static public let completeProfileAssetIdentifierKey = #keyPath(ZMUser.completeProfileAssetIdentifier)

    @NSManaged public var previewProfileAssetIdentifier: String?
    @NSManaged public var completeProfileAssetIdentifier: String?

    /// Conversations created by this user
    @NSManaged var conversationsCreated: Set<ZMConversation>

    /// Team membership for this user
    @NSManaged public internal(set) var membership: Member?

    /// Reactions expressed by this user
    @NSManaged var reactions: Set<Reaction>

    /// System messages referencing this user
    @NSManaged var systemMessages: Set<ZMSystemMessage>

    @NSManaged public var expiresAt: Date?

    /// `accountIsDeleted` is true if this account has been deleted on the backend
    @NSManaged public internal(set) var isAccountDeleted: Bool

    @NSManaged public var usesCompanyLogin: Bool

    /// If `needsToRefetchLabels` is true we need to refetch the conversation labels (favorites & folders)
    @NSManaged public var needsToRefetchLabels: Bool

    @NSManaged public var domain: String?

    @objc(setImageData:size:)
    public func setImage(data: Data?, size: ProfileImageSize) {
        guard let imageData = data else {
            managedObjectContext?.zm_userImageCache?.removeAllUserImages(self)
            return
        }
        managedObjectContext?.zm_userImageCache?.setUserImage(self, imageData: imageData, size: size)

        if let uiContext = managedObjectContext?.zm_userInterface {
            let changedKey = size == .preview ? #keyPath(ZMUser.previewImageData) : #keyPath(ZMUser.completeImageData)
            NotificationDispatcher.notifyNonCoreDataChanges(objectID: objectID, changedKeys: [changedKey], uiContext: uiContext)
        }
    }

    public func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (_ imageData: Data?) -> Void) {
        managedObjectContext?.zm_userImageCache?.userImage(self, size: size, queue: queue, completion: completion)
    }

    @objc(imageDataforSize:)
    public func imageData(for size: ProfileImageSize) -> Data? {
        return managedObjectContext?.zm_userImageCache?.userImage(self, size: size)
    }

    public static var previewImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.previewProfileAssetIdentifierKey)
        let assetIdIsValid = NSPredicate { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.previewProfileAssetIdentifier?.isValidAssetID ?? false
        }
        let notCached = NSPredicate { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageSmallProfileData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, assetIdIsValid, notCached])
    }

    public static var completeImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.completeProfileAssetIdentifierKey)
        let assetIdIsValid = NSPredicate { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.completeProfileAssetIdentifier?.isValidAssetID ?? false
        }
        let notCached = NSPredicate { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageMediumData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, assetIdIsValid, notCached])
    }

    public func updateAndSyncProfileAssetIdentifiers(previewIdentifier: String, completeIdentifier: String) {
        guard isSelfUser else { return }
        previewProfileAssetIdentifier = previewIdentifier
        completeProfileAssetIdentifier = completeIdentifier
        setLocallyModifiedKeys([ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey])
    }

    @objc public func updateAssetData(with assets: NSArray?, authoritative: Bool) {
        guard !hasLocalModifications(forKeys: [ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey]) else { return }
        guard let assets = assets as? [[String: String]], !assets.isEmpty else {
            if authoritative {
                previewProfileAssetIdentifier = nil
                completeProfileAssetIdentifier = nil
            }
            return
        }
        for data in assets {
            if let size = data["size"].flatMap(ProfileImageSize.init), let key = data["key"].flatMap(AssetKey.init) {
                switch size {
                case .preview:
                    if key.stringValue != previewProfileAssetIdentifier {
                        previewProfileAssetIdentifier = key.stringValue
                    }
                case .complete:
                    if key.stringValue != completeProfileAssetIdentifier {
                        completeProfileAssetIdentifier = key.stringValue
                    }
                }
            }
        }
    }

    @objc public func requestPreviewProfileImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(self, size: .preview) else { return }

        NotificationInContext(name: .userDidRequestPreviewAsset,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }

    @objc public func requestCompleteProfileImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(self, size: .complete) else { return }

        NotificationInContext(name: .userDidRequestCompleteAsset,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }

    /// Mark the user's account as having been deleted. This will also remove the user from any conversations he/she
    /// is still a participant of.
    @objc public func markAccountAsDeleted(at timestamp: Date) {
        isAccountDeleted = true
        removeFromAllConversations(at: timestamp)
    }

    /// Remove user from all group conversations he is a participant of
    fileprivate func removeFromAllConversations(at timestamp: Date) {
        let allGroupConversations: [ZMConversation] = participantRoles.compactMap {
            guard let convo = $0.conversation,
                convo.conversationType == .group else { return nil}
            return convo
        }

        allGroupConversations.forEach { conversation in
            if isTeamMember && conversation.team == team {
                conversation.appendTeamMemberRemovedSystemMessage(user: self, at: timestamp)
            } else {
                conversation.appendParticipantRemovedSystemMessage(user: self, at: timestamp)
            }
            conversation.removeParticipantAndUpdateConversationState(user: self, initiatingUser: self)
        }
    }
}

extension ZMUser {
    // MARK: - Participant role

    @objc
    public var conversations: Set<ZMConversation> {
        return Set(participantRoles.compactMap { return $0.conversation })
    }
}

extension NSManagedObject: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        let moc: String = self.managedObjectContext?.description ?? "nil"

        return "\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): moc=\(moc) objectID=\(self.objectID)"
    }
}

extension ZMUser {

    /// The initials e.g. "JS" for "John Smith"
    @objc public var initials: String? {
        return PersonName.person(withName: self.name ?? "", schemeTagger: nil).initials
    }
}

extension ZMUser: UserConnections {

    public func connect(completion: @escaping (Error?) -> Void) {
        ZMUser.selfUser(in: managedObjectContext!).sendConnectionRequest(to: self) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func accept(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.accepted, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

    public func ignore(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.ignored, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

    public func block(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.blocked, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

    public func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.cancelled, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

}
