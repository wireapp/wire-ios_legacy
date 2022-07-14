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

extension CoreCrypto: WireDataModel.CoreCryptoProtocol {

    public func wire_setCallbacks(callbacks: WireDataModel.CoreCryptoCallbacks) throws {
        guard let callbacks = callbacks as? WireCoreCrypto.CoreCryptoCallbacks else {
            fatalError("`callbacks` does not conform to `WireCoreCrypto.CoreCryptoCallbacks`")
        }

        try setCallbacks(callbacks: callbacks)
    }

    public func wire_clientPublicKey() throws -> [UInt8] {
        return try clientPublicKey()
    }

    public func wire_clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        return try clientKeypackages(amountRequested: amountRequested)
    }

    public func wire_createConversation(
        conversationId: WireDataModel.ConversationId,
        config: WireDataModel.ConversationConfiguration
    ) throws {
        return try createConversation(
            conversationId: conversationId,
            config: .init(config: config)
        )
    }

    public func wire_conversationExists(conversationId: WireDataModel.ConversationId) -> Bool {
        return conversationExists(conversationId: conversationId)
    }

    public func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> [UInt8] {
        return try processWelcomeMessage(welcomeMessage: welcomeMessage)
    }

    public func wire_addClientsToConversation(
        conversationId: WireDataModel.ConversationId,
        clients: [WireDataModel.Invitee]
    ) throws -> WireDataModel.MemberAddedMessages? {
        return try addClientsToConversation(
            conversationId: conversationId,
            clients: clients.map(WireCoreCrypto.Invitee.init)
        ).map(WireDataModel.MemberAddedMessages.init)
    }

    public func wire_removeClientsFromConversation(
        conversationId: WireDataModel.ConversationId,
        clients: [WireDataModel.ClientId]
    ) throws -> [UInt8]? {
        return try removeClientsFromConversation(
            conversationId: conversationId,
            clients: clients
        )
    }

    public func wire_leaveConversation(
        conversationId: WireDataModel.ConversationId,
        otherClients: [WireDataModel.ClientId]
    ) throws -> WireDataModel.ConversationLeaveMessages {
        let result =  try leaveConversation(
            conversationId: conversationId,
            otherClients: otherClients
        )

        return .init(messages: result)
    }

    public func wire_decryptMessage(
        conversationId: WireDataModel.ConversationId,
        payload: [UInt8]
    ) throws -> [UInt8]? {
        return try decryptMessage(
            conversationId: conversationId,
            payload: payload
        )
    }

    public func wire_encryptMessage(
        conversationId: WireDataModel.ConversationId,
        message: [UInt8]
    ) throws -> [UInt8] {
        return try encryptMessage(
            conversationId: conversationId,
            message: message
        )
    }

    public func wire_newAddProposal(
        conversationId: WireDataModel.ConversationId,
        keyPackage: [UInt8]
    ) throws -> [UInt8] {
        return try newAddProposal(
            conversationId: conversationId,
            keyPackage: keyPackage
        )
    }

    public func wire_newUpdateProposal(conversationId: WireDataModel.ConversationId) throws -> [UInt8] {
        return try newUpdateProposal(conversationId: conversationId)
    }

    public func wire_newRemoveProposal(
        conversationId: WireDataModel.ConversationId,
        clientId: WireDataModel.ClientId
    ) throws -> [UInt8] {
        return try newRemoveProposal(
            conversationId: conversationId,
            clientId: clientId
        )
    }

    public func wire_newExternalAddProposal(
        conversationId: WireDataModel.ConversationId,
        epoch: UInt64,
        keyPackage: [UInt8]
    ) throws -> [UInt8] {
        return try newExternalAddProposal(
            conversationId: conversationId,
            epoch: epoch,
            keyPackage: keyPackage
        )
    }

    public func wire_newExternalRemoveProposal(
        conversationId: WireDataModel.ConversationId,
        epoch: UInt64,
        keyPackageRef: [UInt8]
    ) throws -> [UInt8] {
        return try newExternalRemoveProposal(
            conversationId: conversationId,
            epoch: epoch,
            keyPackageRef: keyPackageRef
        )
    }

    public func wire_updateKeyingMaterial(conversationId: WireDataModel.ConversationId) throws -> WireDataModel.CommitBundle {
        let result = try updateKeyingMaterial(conversationId: conversationId)
        return .init(welcome: result.welcome, message: result.message)
    }

    public func wire_joinByExternalCommit(groupState: [UInt8]) throws -> WireDataModel.MlsConversationInitMessage {
        let result = try joinByExternalCommit(groupState: groupState)
        return .init(group: result.group, message: result.message)
    }

    public func wire_exportGroupState(conversationId: WireDataModel.ConversationId) throws -> [UInt8] {
        return try exportGroupState(conversationId: conversationId)
    }

    public func wire_mergePendingGroupFromExternalCommit(
        conversationId: WireDataModel.ConversationId,
        config: WireDataModel.ConversationConfiguration
    ) throws {
        try mergePendingGroupFromExternalCommit(
            conversationId: conversationId,
            config: .init(config: config)
        )
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

    init(messages: WireCoreCrypto.MemberAddedMessages) {
        self.init(
            message: messages.message,
            welcome: messages.welcome
        )
    }

}

private extension WireDataModel.ConversationLeaveMessages {

    init(messages: WireCoreCrypto.ConversationLeaveMessages) {
        self.init(
            selfRemovalProposal: messages.selfRemovalProposal,
            otherClientsRemovalCommit: messages.otherClientsRemovalCommit
        )
    }

}
