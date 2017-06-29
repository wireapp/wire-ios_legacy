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

extension UserClient {
    // Migration method for merging two duplicated @c UserClient entities
    public func merge(with client: UserClient) {
        precondition(!(self.user?.isSelfUser ?? false), "Cannot merge self user's clients")
        precondition(client.remoteIdentifier == self.remoteIdentifier, "UserClient's remoteIdentifier should be equal to merge")
        precondition(client.user == self.user, "UserClient's Users should be equal to merge")
        
        let addedOrRemovedInSystemMessages = client.addedOrRemovedInSystemMessages
        let ignoredByClients = client.ignoredByClients
        let messagesMissingRecipient = client.messagesMissingRecipient
        let trustedByClients = client.trustedByClients
        
        self.addedOrRemovedInSystemMessages.formUnion(addedOrRemovedInSystemMessages)
        self.ignoredByClients.formUnion(ignoredByClients)
        self.messagesMissingRecipient.formUnion(messagesMissingRecipient)
        self.trustedByClients.formUnion(trustedByClients)
        
        if let missedByClient = client.missedByClient {
            self.missedByClient = missedByClient
        }
    }
}

extension ZMHotFixDirectory {

    public static func moveOrUpdateSignalingKeysInContext(_ context: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient()
              , selfClient.apsVerificationKey == nil && selfClient.apsDecryptionKey == nil
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
    
    /// In the model schema version 2.6 we removed the flags `needsToUploadMedium` and `needsToUploadPreview` on `ZMAssetClientMessage`
    /// and introduced an enum called `ZMAssetUploadedState`. During the migration this value will be set to `.Done` on all `ZMAssetClientMessages`.
    /// There is an edge case in which the user has such a message in his database which is not yet uploaded and we want to upload it again, thus
    /// not set the state to `.Done` in this case. We fetch all asset messages without an assetID and set set their uploaded state 
    /// to `.UploadingFailed`, in case this message represents an image we also expire it.
    public static func updateUploadedStateForNotUploadedFileMessages(_ context: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: context)
        let predicate = NSPredicate(format: "sender == %@ AND assetId_data == NULL", selfUser)
        let fetchRequest = ZMAssetClientMessage.sortedFetchRequest(with: predicate)
        guard let messages = context.executeFetchRequestOrAssert(fetchRequest) as? [ZMAssetClientMessage] else { return }
        
        messages.forEach { message in
            message.uploadState = .uploadingFailed
            if nil != message.imageMessageData {
                message.expire()
            }
        }
        
        context.enqueueDelayedSave()
    }
    
    public static func insertNewConversationSystemMessage(_ context: NSManagedObjectContext) {
        let fetchRequest = ZMConversation.sortedFetchRequest()
        guard let conversations = context.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation] else { return }
        
        // Conversation Type Group are ongoing, active conversation
        conversations.filter { $0.conversationType == .group }.forEach {
            $0.appendNewConversationSystemMessageIfNeeded()
        }
    }
    
    public static func updateSystemMessages(_ context: NSManagedObjectContext) {
        let fetchRequest = ZMConversation.sortedFetchRequest()
        guard let conversations = context.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation] else { return }
        let filteredConversations =  conversations.filter{ $0.conversationType == .oneOnOne || $0.conversationType == .group }
        
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

    /// Marks all connected users (including self) to be refetched.
    /// Unconnected users are refreshed with a call to `refreshData` when information is displayed.
    /// See also the related `ZMUserSession.isPendingHotFixChanges` in `ZMHotFix+PendingChanges.swift`.
    public static func refetchConnectedUsers(_ context: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "connection != nil")
        let request = ZMUser.sortedFetchRequest(with: predicate)
        let users = context.executeFetchRequestOrAssert(request) as? [ZMUser]

        users?.lazy
            .filter { $0.isConnected }
            .forEach { $0.needsToBeUpdatedFromBackend = true }

        ZMUser.selfUser(in: context).needsToBeUpdatedFromBackend = true
        context.enqueueDelayedSave()
    }

    public static func restartSlowSync() {
        NotificationCenter.default.post(name: .ForceSlowSync, object: nil)
    }
    
    public static func deleteDuplicatedClients(in context: NSManagedObjectContext) {
        // Fetch clients having the same remote identifiers
        context.findDuplicated(by: #keyPath(UserClient.remoteIdentifier)).forEach { (remoteId: String?, clients: [UserClient]) in
            // Group clients having the same remote identifiers by user
            clients.filter { !($0.user?.isSelfUser ?? true) }.group(by: ZMUserClientUserKey).forEach { (user: ZMUser, clients: [UserClient]) in
                guard let firstClient = clients.first, clients.count > 1 else {
                    return
                }
                
                let tail = clients.dropFirst()
                // Merge clients having the same remote identifier and same user
                
                tail.forEach {
                    firstClient.merge(with: $0)
                    context.delete($0)
                }
            }
        }
    }
}
