// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@objc extension ZMHotFixDirectory {

    public static func moveOrUpdateSignalingKeysInContext(_ context: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient(), selfClient.apsVerificationKey == nil && selfClient.apsDecryptionKey == nil
        else { return }

        if let keys = APSSignalingKeysStore.keysStoredInKeyChain() {
            selfClient.apsVerificationKey = keys.verificationKey
            selfClient.apsDecryptionKey = keys.decryptionKey
            APSSignalingKeysStore.clearSignalingKeysInKeyChain()
        } else {
            UserClient.resetSignalingKeysInContext(context)
        }

        context.enqueueDelayedSave()
    }

    public static func updateClientCapabilities(_ context: NSManagedObjectContext) {
        UserClient.triggerSelfClientCapabilityUpdate(context)
    }

    /// In the model schema version 2.6 we removed the flags `needsToUploadMedium` and `needsToUploadPreview` on `ZMAssetClientMessage`
    /// and introduced an enum called `ZMAssetUploadedState`. During the migration this value will be set to `.Done` on all `ZMAssetClientMessages`.
    /// There is an edge case in which the user has such a message in his database which is not yet uploaded and we want to upload it again, thus
    /// not set the state to `.Done` in this case. We fetch all asset messages without an assetID and set set their uploaded state 
    /// to `.UploadingFailed`, in case this message represents an image we also expire it.
    public static func updateUploadedStateForNotUploadedFileMessages(_ context: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: context)
        let predicate = NSPredicate(format: "sender == %@ AND assetId_data == NULL", selfUser)

        let fetchRequest = ZMAssetClientMessage.sortedFetchRequest(with: predicate)

        guard let messages = context.fetchOrAssert(request: fetchRequest) as? [ZMAssetClientMessage] else { return }

        messages.forEach { message in
            message.updateTransferState(.uploadingFailed, synchronize: false)
            if nil != message.imageMessageData {
                message.expire()
            }
        }

        context.enqueueDelayedSave()
    }

    public static func insertNewConversationSystemMessage(_ context: NSManagedObjectContext) {
        let fetchRequest = ZMConversation.sortedFetchRequest()

        guard let conversations = context.fetchOrAssert(request: fetchRequest) as? [ZMConversation] else { return }

        // Add .newConversation system message in all group conversations if not already present
        conversations.filter { $0.conversationType == .group }.forEach { conversation in

            let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
            fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMMessageConversationKey, conversation.objectID)
            fetchRequest.sortDescriptors = ZMMessage.defaultSortDescriptors()
            fetchRequest.fetchLimit = 1

            let messages = context.fetchOrAssert(request: fetchRequest)

            if let firstSystemMessage = messages.first as? ZMSystemMessage, firstSystemMessage.systemMessageType == .newConversation {
                return // Skip if conversation already has a .newConversation system message
            }

            conversation.appendNewConversationSystemMessage(at: Date.distantPast, users: conversation.localParticipants)
        }
    }

    public static func markAllNewConversationSystemMessagesAsRead(_ context: NSManagedObjectContext) {

        let fetchRequest = ZMConversation.sortedFetchRequest()

        guard let conversations = context.fetchOrAssert(request: fetchRequest) as? [ZMConversation] else { return }

        conversations.filter({ $0.conversationType == .group }).forEach { conversation in

            let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
            fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMMessageConversationKey, conversation.objectID)
            fetchRequest.sortDescriptors = ZMMessage.defaultSortDescriptors()
            fetchRequest.fetchLimit = 1

            let messages = context.fetchOrAssert(request: fetchRequest)

            // Mark the first .newConversation system message as read if it's not already read.
            if let firstSystemMessage = messages.first as? ZMSystemMessage, firstSystemMessage.systemMessageType == .newConversation,
               let serverTimestamp = firstSystemMessage.serverTimestamp {

                guard let lastReadServerTimeStamp = conversation.lastReadServerTimeStamp else {
                    // if lastReadServerTimeStamp is nil the conversation was never read
                    return conversation.lastReadServerTimeStamp = serverTimestamp
                }

                if serverTimestamp > lastReadServerTimeStamp {
                    // conversation was read but not up until our system message
                    conversation.lastReadServerTimeStamp = serverTimestamp
                }
            }
        }
    }

    public static func updateSystemMessages(_ context: NSManagedObjectContext) {
        let fetchRequest = ZMConversation.sortedFetchRequest()

        guard let conversations = context.fetchOrAssert(request: fetchRequest) as? [ZMConversation] else { return }
        let filteredConversations =  conversations.filter { $0.conversationType == .oneOnOne || $0.conversationType == .group }

        // update "you are using this device" message
        filteredConversations.forEach {
            $0.replaceNewClientMessageIfNeededWithNewDeviceMesssage()
        }
    }

    public static func purgePINCachesInHostBundle() {
        let fileManager = FileManager.default
        guard let cachesDirectory = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
        let PINCacheFolders = ["com.pinterest.PINDiskCache.images", "com.pinterest.PINDiskCache.largeUserImages", "com.pinterest.PINDiskCache.smallUserImages"]

        PINCacheFolders.forEach { PINCacheFolder in
            let cacheDirectory =  cachesDirectory.appendingPathComponent(PINCacheFolder, isDirectory: true)
            try? fileManager.removeItem(at: cacheDirectory)
        }
    }

    /// Marks all users (excluding self) to be refetched.
    public static func refetchUsers(_ context: NSManagedObjectContext) {
        let request = ZMUser.sortedFetchRequest()

        let users = context.fetchOrAssert(request: request) as? [ZMUser]

        users?.lazy
            .filter { !$0.isSelfUser }
            .forEach { $0.needsToBeUpdatedFromBackend = true }

        context.enqueueDelayedSave()
    }

    /// Refreshes the self user.
    public static func refetchSelfUser(_ context: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.needsToBeUpdatedFromBackend = true
        context.enqueueDelayedSave()
    }

    /// Marks all connected users (including self) to be refetched.
    /// Unconnected users are refreshed with a call to `refreshData` when information is displayed.
    /// See also the related `ZMUserSession.isPendingHotFixChanges` in `ZMHotFix+PendingChanges.swift`.
    public static func refetchConnectedUsers(_ context: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "connection != nil")
        let request = ZMUser.sortedFetchRequest(with: predicate)

        let users = context.fetchOrAssert(request: request) as? [ZMUser]

        users?.lazy
            .filter { $0.isConnected }
            .forEach { $0.needsToBeUpdatedFromBackend = true }

        ZMUser.selfUser(in: context).needsToBeUpdatedFromBackend = true
        context.enqueueDelayedSave()
    }

    public static func restartSlowSync(_ context: NSManagedObjectContext) {
        NotificationInContext(name: .ForceSlowSync, context: context.notificationContext).post()
    }

    /// Marks all conversations created in a team to be refetched.
    /// This is needed because we have introduced access levels when implementing
    /// wireless guests feature
    public static func refetchTeamGroupConversations(_ context: NSManagedObjectContext) {
        // Batch update changes the underlying data in the persistent store and should be much more
        let predicate = NSPredicate(format: "team != nil AND %K == %d",
                                    ZMConversationConversationTypeKey,
                                    ZMConversationType.group.rawValue)
        refetchConversations(matching: predicate, in: context)
    }

    /// Marks all group conversations to be refetched.
    public static func refetchGroupConversations(_ context: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %d AND ANY %K.user == %@",
                                    ZMConversationConversationTypeKey,
                                    ZMConversationType.group.rawValue,
                                    ZMConversationParticipantRolesKey,
                                    ZMUser.selfUser(in: context))
        refetchConversations(matching: predicate, in: context)
    }

    public static func refetchUserProperties(_ context: NSManagedObjectContext) {
        ZMUser.selfUser(in: context).needsPropertiesUpdate = true
        context.enqueueDelayedSave()
    }

    public static func refetchTeamMembers(_ context: NSManagedObjectContext) {
        ZMUser.selfUser(in: context).team?.members.forEach({ member in
            member.needsToBeUpdatedFromBackend = true
        })
    }

    /// Marks all conversations to be refetched.
    public static func refetchAllConversations(_ context: NSManagedObjectContext) {
        refetchConversations(matching: NSPredicate(value: true), in: context)
    }

    private static func refetchConversations(matching predicate: NSPredicate, in context: NSManagedObjectContext) {
        let request = ZMConversation.sortedFetchRequest(with: predicate)

        let conversations = context.fetchOrAssert(request: request) as? [ZMConversation]

        conversations?.forEach { $0.needsToBeUpdatedFromBackend = true }
        context.enqueueDelayedSave()
    }

    public static func refetchLabels(_ context: NSManagedObjectContext) {
        ZMUser.selfUser(in: context).needsToRefetchLabels = true
    }

    public static func migrateBackendEnvironmentToSharedUserDefaults() {
        guard let sharedUserDefaults = UserDefaults.shared() else { return }

        BackendEnvironment.migrate(from: .standard, to: sharedUserDefaults)
    }

    public static func removeDeliveryReceiptsForDeletedMessages(_ context: NSManagedObjectContext) {
        guard let predicate = ZMClientMessage.predicateForObjectsThatNeedToBeInsertedUpstream() else {
            return
        }

        let requestForInsertedMessages = ZMClientMessage.sortedFetchRequest(with: predicate)

        guard let possibleMatches = context.fetchOrAssert(request: requestForInsertedMessages) as? [ZMClientMessage] else {
            return
        }

        let confirmationReceiptsForDeletedMessages = possibleMatches.filter({ candidate in
            guard
                let conversation = candidate.conversation,
                let underlyingMessage = candidate.underlyingMessage,
                underlyingMessage.hasConfirmation else {
                    return false
            }

            let originalMessageUUID = UUID(uuidString: underlyingMessage.confirmation.firstMessageID)
            let originalConfirmedMessage = ZMMessage.fetch(withNonce: originalMessageUUID, for: conversation, in: context)
            guard
                let message = originalConfirmedMessage,
                message.hasBeenDeleted || message.sender == nil else {
                    return false
            }
            return true
        })

        for message in confirmationReceiptsForDeletedMessages {
            context.delete(message)
        }

        context.saveOrRollback()
    }
}
