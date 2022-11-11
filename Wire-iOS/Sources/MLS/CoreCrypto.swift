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
import CoreCrypto

extension CoreCryptoWrapper: WireDataModel.CoreCryptoProtocol {

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

    public func wire_createConversation(conversationId: ConversationId, config: WireDataModel.ConversationConfiguration) throws {
        try createConversation(conversationId: conversationId, config: .init(config: config))
    }

    public func wire_conversationEpoch(conversationId: ConversationId) throws -> UInt64 {
        return try conversationEpoch(conversationId: conversationId)
    }

    public func wire_conversationExists(conversationId: ConversationId) -> Bool {
        return conversationExists(conversationId: conversationId)
    }

    public func wire_processWelcomeMessage(welcomeMessage: [UInt8]) throws -> ConversationId {
        return try processWelcomeMessage(welcomeMessage: welcomeMessage)
    }

    public func wire_addClientsToConversation(conversationId: ConversationId, clients: [WireDataModel.Invitee]) throws -> WireDataModel.MemberAddedMessages {
        return try .init(addClientsToConversation(conversationId: conversationId, clients: clients.map(Invitee.init)))
    }

    public func wire_removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> WireDataModel.CommitBundle {
        return try .init(removeClientsFromConversation(conversationId: conversationId, clients: clients))
    }

    public func wire_updateKeyingMaterial(conversationId: ConversationId) throws -> WireDataModel.CommitBundle {
        return try .init(updateKeyingMaterial(conversationId: conversationId))
    }

    public func wire_commitPendingProposals(conversationId: ConversationId) throws -> WireDataModel.CommitBundle? {
        guard let result = try commitPendingProposals(conversationId: conversationId) else { return nil }
        return .init(result)
    }

    public func wire_wipeConversation(conversationId: ConversationId) throws {
        try wipeConversation(conversationId: conversationId)
    }

    public func wire_decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> WireDataModel.DecryptedMessage {
        return try .init(decryptMessage(conversationId: conversationId, payload: payload))
    }

    public func wire_encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        return try encryptMessage(conversationId: conversationId, message: message)
    }

    public func wire_newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> WireDataModel.ProposalBundle {
        return try .init(newAddProposal(conversationId: conversationId, keyPackage: keyPackage))
    }

    public func wire_newUpdateProposal(conversationId: ConversationId) throws -> WireDataModel.ProposalBundle {
        return try .init(newUpdateProposal(conversationId: conversationId))
    }

    public func wire_newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> WireDataModel.ProposalBundle {
        return try .init(newRemoveProposal(conversationId: conversationId, clientId: clientId))
    }

    public func wire_newExternalAddProposal(conversationId: ConversationId, epoch: UInt64) throws -> [UInt8] {
        return try newExternalAddProposal(conversationId: conversationId, epoch: epoch)
    }

    public func wire_newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        return try newExternalRemoveProposal(conversationId: conversationId, epoch: epoch, keyPackageRef: keyPackageRef)
    }

    public func wire_joinByExternalCommit(groupState: [UInt8]) throws -> WireDataModel.ConversationInitBundle {
        return try .init(joinByExternalCommit(publicGroupState: groupState))
    }

    public func wire_exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        return try exportGroupState(conversationId: conversationId)
    }

    public func wire_mergePendingGroupFromExternalCommit(conversationId: ConversationId, config: WireDataModel.ConversationConfiguration) throws {
        try mergePendingGroupFromExternalCommit(conversationId: conversationId, config: .init(config: config))
    }

    public func wire_clearPendingGroupFromExternalCommit(conversationId: ConversationId) throws {
        try clearPendingGroupFromExternalCommit(conversationId: conversationId)
    }

    public func wire_exportSecretKey(conversationId: ConversationId, keyLength: UInt32) throws -> [UInt8] {
        try exportSecretKey(conversationId: conversationId, keyLength: keyLength)
    }

    public func wire_getClientIds(conversationId: ConversationId) throws -> [ClientId] {
        try getClientIds(conversationId: conversationId)
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

    public func wire_clearPendingProposal(conversationId: ConversationId, proposalRef: [UInt8]) throws {
//        try clearPendingProposal(conversationId: conversationId, proposalRef: proposalRef)
    }

    public func wire_clearPendingCommit(conversationId: ConversationId) throws {
//        try clearPendingCommit(conversationId: conversationId)
    }

    public func wire_proteusInit() throws {
        try proteusInit()
    }

    public func wire_proteusSessionFromPrekey(sessionId: String, prekey: [UInt8]) throws {
        try proteusSessionFromPrekey(sessionId: sessionId, prekey: prekey)
    }

    public func wire_proteusSessionFromMessage(sessionId: String, envelope: [UInt8]) throws -> [UInt8] {
        try proteusSessionFromMessage(sessionId: sessionId, envelope: envelope)
    }

    public func wire_proteusSessionSave(sessionId: String) throws {
        try proteusSessionSave(sessionId: sessionId)
    }

    public func wire_proteusSessionDelete(sessionId: String) throws {
        try proteusSessionDelete(sessionId: sessionId)
    }

    public func wire_proteusDecrypt(sessionId: String, ciphertext: [UInt8]) throws -> [UInt8] {
        try proteusDecrypt(sessionId: sessionId, ciphertext: ciphertext)
    }

    public func wire_proteusEncrypt(sessionId: String, plaintext: [UInt8]) throws -> [UInt8] {
        try proteusEncrypt(sessionId: sessionId, plaintext: plaintext)
    }

    public func wire_proteusEncryptBatched(sessionId: [String], plaintext: [UInt8]) throws -> [String : [UInt8]] {
        try proteusEncryptBatched(sessions: sessionId, plaintext: plaintext)
    }

    public func wire_proteusNewPrekey(prekeyId: UInt16) throws -> [UInt8] {
        try proteusNewPrekey(prekeyId: prekeyId)
    }

    public func wire_proteusFingerprint() throws -> String {
        try proteusFingerprint()
    }

    public func wire_proteusCryptoboxMigrate(path: String) throws {
        try proteusCryptoboxMigrate(path: path)
    }
}

private extension CoreCrypto.ConversationConfiguration {

    init(config: WireDataModel.ConversationConfiguration) {
        let ciphersuite = config.ciphersuite.map(CoreCrypto.CiphersuiteName.init)

        self.init(
            admins: config.admins,
            ciphersuite: ciphersuite,
            keyRotationSpan: config.keyRotationSpan,
            externalSenders: config.externalSenders
        )
    }

}

private extension CoreCrypto.Invitee {

    init(invitee: WireDataModel.Invitee) {
        self.init(
            id: invitee.id,
            kp: invitee.kp
        )
    }

}

private extension CoreCrypto.CiphersuiteName {

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

    init(_ messages: CoreCrypto.MemberAddedMessages) {
        self.init(
            commit: messages.commit,
            welcome: messages.welcome,
            publicGroupState: .init(messages.publicGroupState)
        )
    }

}

private extension WireDataModel.CommitBundle {

    init(_ commitBundle: CoreCrypto.CommitBundle) {
        self.init(
            welcome: commitBundle.welcome,
            commit: commitBundle.commit,
            publicGroupState: .init(commitBundle.publicGroupState)
        )
    }

}

private extension WireDataModel.ProposalBundle {

    init(_ proposalBundle: CoreCrypto.ProposalBundle) {
        self.init(
            proposal: proposalBundle.proposal,
            proposalRef: proposalBundle.proposalRef
        )
    }

}

private extension WireDataModel.DecryptedMessage {

    init(_ decryptedMessage: CoreCrypto.DecryptedMessage) {
        self.init(
            message: decryptedMessage.message,
            proposals: decryptedMessage.proposals.map(WireDataModel.ProposalBundle.init),
            isActive: decryptedMessage.isActive,
            commitDelay: decryptedMessage.commitDelay,
            senderClientId: decryptedMessage.senderClientId
        )
    }

}

private extension WireDataModel.ConversationInitBundle {

    init(_ bundle: CoreCrypto.ConversationInitBundle) {
        self.init(
            conversationId: bundle.conversationId,
            commit: bundle.commit,
            publicGroupState: .init(bundle.publicGroupState)
        )
    }

}

private extension WireDataModel.PublicGroupStateBundle {

    init(_ bundle: CoreCrypto.PublicGroupStateBundle) {
        self.init(
            encryptionType: .init(bundle.encryptionType),
            ratchetTreeType: .init(bundle.ratchetTreeType),
            payload: bundle.payload
        )
    }

}

private extension WireDataModel.PublicGroupStateEncryptionType {

    init(_ encryptionType: CoreCrypto.PublicGroupStateEncryptionType) {
        switch encryptionType {
        case .JweEncrypted:
            self = .JweEncrypted
        case .Plaintext:
            self = .Plaintext
        }
    }

}

private extension WireDataModel.RatchetTreeType {

    init(_ ratchetTreeType: CoreCrypto.RatchetTreeType) {
        switch ratchetTreeType {
        case .ByRef:
            self = .ByRef
        case .Delta:
            self = .Delta
        case .Full:
            self = .Full
        }
    }

}
