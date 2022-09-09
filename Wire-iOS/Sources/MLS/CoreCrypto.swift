//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCoreCrypto

class CoreCryptoCallbacksWrapper: WireCoreCrypto.CoreCryptoCallbacks {

    let callbacks: WireDataModel.CoreCryptoCallbacks

    init(callbacks: WireDataModel.CoreCryptoCallbacks) {
        self.callbacks = callbacks
    }

    func authorize(conversationId: [UInt8], clientId: String) -> Bool {
        return callbacks.authorize(conversationId: conversationId, clientId: clientId)
    }

    func isUserInGroup(identity: [UInt8], otherClients: [[UInt8]]) -> Bool {
        return callbacks.isUserInGroup(identity: identity, otherClients: otherClients)
    }

}

extension CoreCrypto: WireDataModel.CoreCryptoProtocol {

    public func wire_setCallbacks(callbacks: WireDataModel.CoreCryptoCallbacks) throws {
        try setCallbacks(callbacks: CoreCryptoCallbacksWrapper(callbacks: callbacks))
    }

    public func wire_clientPublicKey() throws -> [UInt8] {
        return try clientPublicKey()
    }

    public func wire_clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        return try clientKeypackages(amountRequested: amountRequested)
    }

    public func wire_clientValidKeypackagesCount() throws -> UInt64 {
        return try clientValidKeypackagesCount()
    }

    public func wire_createConversation(
        conversationId: ConversationId,
        config: WireDataModel.ConversationConfiguration
    ) throws {
        return try createConversation(
            conversationId: conversationId,
            config: .init(config: config)
        )
    }

    public func wire_conversationExists(conversationId: ConversationId) -> Bool {
        return conversationExists(conversationId: conversationId)
    }

    public func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> ConversationId {
        return try processWelcomeMessage(welcomeMessage: welcomeMessage)
    }

    public func wire_addClientsToConversation(
        conversationId: ConversationId,
        clients: [WireDataModel.Invitee]
    ) throws -> WireDataModel.MemberAddedMessages {
        let result = try addClientsToConversation(
            conversationId: conversationId,
            clients: clients.map(Invitee.init)
        )

        return .init(result)
    }

    public func wire_removeClientsFromConversation(
        conversationId: ConversationId,
        clients: [ClientId]
    ) throws -> WireDataModel.CommitBundle {
        let result = try removeClientsFromConversation(
            conversationId: conversationId,
            clients: clients
        )

        return .init(result)
    }

    public func wire_wipeConversation(conversationId: ConversationId) throws {
        return try wipeConversation(conversationId: conversationId)
    }

    public func wire_decryptMessage(
        conversationId: ConversationId,
        payload: [UInt8]
    ) throws -> WireDataModel.DecryptedMessage {
        let result = try decryptMessage(
            conversationId: conversationId,
            payload: payload
        )

        return .init(result)
    }

    public func wire_encryptMessage(
        conversationId: ConversationId,
        message: [UInt8]
    ) throws -> [UInt8] {
        return try encryptMessage(
            conversationId: conversationId,
            message: message
        )
    }

    public func wire_newAddProposal(
        conversationId: ConversationId,
        keyPackage: [UInt8]
    ) throws -> [UInt8] {
        return try newAddProposal(
            conversationId: conversationId,
            keyPackage: keyPackage
        )
    }

    public func wire_newUpdateProposal(conversationId: ConversationId) throws -> [UInt8] {
        return try newUpdateProposal(conversationId: conversationId)
    }

    public func wire_newRemoveProposal(
        conversationId: ConversationId,
        clientId: ClientId
    ) throws -> [UInt8] {
        return try newRemoveProposal(
            conversationId: conversationId,
            clientId: clientId
        )
    }

    public func wire_newExternalAddProposal(
        conversationId: ConversationId,
        epoch: UInt64
    ) throws -> [UInt8] {
        return try newExternalAddProposal(
            conversationId: conversationId,
            epoch: epoch
        )
    }

    public func wire_newExternalRemoveProposal(
        conversationId: ConversationId,
        epoch: UInt64,
        keyPackageRef: [UInt8]
    ) throws -> [UInt8] {
        return try newExternalRemoveProposal(
            conversationId: conversationId,
            epoch: epoch,
            keyPackageRef: keyPackageRef
        )
    }

    public func wire_updateKeyingMaterial(conversationId: ConversationId) throws -> WireDataModel.CommitBundle {
        let result = try updateKeyingMaterial(conversationId: conversationId)
        return .init(result)
    }

    public func wire_joinByExternalCommit(groupState: [UInt8]) throws -> WireDataModel.MlsConversationInitMessage {
        let result = try joinByExternalCommit(groupState: groupState)
        return .init(
            group: result.group,
            commit: result.commit
        )
    }

    public func wire_exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        return try exportGroupState(conversationId: conversationId)
    }

    public func wire_mergePendingGroupFromExternalCommit(
        conversationId: ConversationId,
        config: WireDataModel.ConversationConfiguration
    ) throws {
        try mergePendingGroupFromExternalCommit(
            conversationId: conversationId,
            config: .init(config: config)
        )
    }

    public func wire_randomBytes(length: UInt32) throws -> [UInt8] {
        return try randomBytes(length: length)
    }

    public func wire_reseedRng(seed: [UInt8]) throws {
        try reseedRng(seed: seed)
    }

    public func wire_commitAccepted(conversationId: ConversationId) throws {
        try commitAccepted(conversationId: conversationId)
    }

    public func wire_commitPendingProposals(conversationId: ConversationId) throws -> WireDataModel.CommitBundle {
        let result = try commitPendingProposals(conversationId: conversationId)
        return .init(result)
    }

}

private extension WireCoreCrypto.ConversationConfiguration {

    init(config: WireDataModel.ConversationConfiguration) {
        let ciphersuite = config.ciphersuite.map(WireCoreCrypto.CiphersuiteName.init)

        self.init(
            admins: config.admins,
            ciphersuite: ciphersuite,
            keyRotationSpan: config.keyRotationSpan,
            externalSenders: config.externalSenders
        )
    }

}

private extension WireCoreCrypto.Invitee {

    init(invitee: WireDataModel.Invitee) {
        self.init(
            id: invitee.id,
            kp: invitee.kp
        )
    }

}

private extension WireCoreCrypto.CiphersuiteName {

    init(cipherSuiteName: WireDataModel.CiphersuiteName) {
        switch cipherSuiteName {
        case .mls128Dhkemx25519Aes128gcmSha256Ed25519:
            self = .mls128Dhkemx25519Aes128gcmSha256Ed25519

        case .mls128Dhkemp256Aes128gcmSha256P256:
            self = .mls128Dhkemp256Aes128gcmSha256P256

        case .mls128Dhkemx25519Chacha20poly1305Sha256Ed25519:
            self = .mls128Dhkemx25519Chacha20poly1305Sha256Ed25519

        case .mls256Dhkemx448Aes256gcmSha512Ed448:
            self = .mls256Dhkemx448Aes256gcmSha512Ed448

        case .mls256Dhkemp521Aes256gcmSha512P521:
            self = .mls256Dhkemp521Aes256gcmSha512P521

        case .mls256Dhkemx448Chacha20poly1305Sha512Ed448:
            self = .mls256Dhkemx448Chacha20poly1305Sha512Ed448

        case .mls256Dhkemp384Aes256gcmSha384P384:
            self = .mls256Dhkemp384Aes256gcmSha384P384
        }
    }

}

private extension WireDataModel.MemberAddedMessages {

    init(_ messages: WireCoreCrypto.MemberAddedMessages) {
        self.init(
            commit: messages.commit,
            welcome: messages.welcome,
            publicGroupState: messages.publicGroupState
        )
    }

}

private extension WireDataModel.CommitBundle {

    init(_ commitBundle: WireCoreCrypto.CommitBundle) {
        self.init(
            welcome: commitBundle.welcome,
            commit: commitBundle.commit,
            publicGroupState: commitBundle.publicGroupState
        )
    }

}

private extension WireDataModel.DecryptedMessage {

    init(_ decryptedMessage: WireCoreCrypto.DecryptedMessage) {
        self.init(
            message: decryptedMessage.message,
            proposals: decryptedMessage.proposals,
            isActive: decryptedMessage.isActive,
            commitDelay: decryptedMessage.commitDelay
        )
    }

}
