//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireMockTransport
import XCTest
import WireTesting
import WireCryptobox
import WireDataModel

extension IntegrationTest {

    /// Encrypts a message from the given client to the self user.
    /// It will create a session between the two if needed
    public func encryptedMessageToSelf(message: GenericMessage, from sender: UserClient) -> Data {

        let selfClient = ZMUser.selfUser(in: self.userSession!.syncManagedObjectContext).selfClient()!
        if selfClient.user!.remoteIdentifier == nil {
            selfClient.user!.remoteIdentifier = UUID()
        }
        if selfClient.remoteIdentifier == nil {
            selfClient.remoteIdentifier = NSString.createAlphanumerical() as String
        }

        var cypherText: Data?
        self.encryptionContext(for: sender).perform { (session) in
            if !session.hasSession(for: selfClient.sessionIdentifier!) {
                guard let lastPrekey = try? selfClient.keysStore.lastPreKey() else {
                    fatalError("Can't get prekey for self user")
                }
                try! session.createClientSession(selfClient.sessionIdentifier!, base64PreKeyString: lastPrekey)
            }

            do {
                cypherText = try session.encrypt(try message.serializedData(), for: selfClient.sessionIdentifier!)
            } catch {
                fatalError("Error in encrypting: \(error)")
            }
        }
        return cypherText!
    }

    /// Creates a session between the self client to the given user, if it does not
    /// exists already
    public func establishSessionFromSelf(to client: UserClient) {

        // this makes sure the client has remote identifier
        _ = self.encryptionContext(for: client)

        if client.hasSessionWithSelfClient {
            // done!
            return
        }

        let selfClient = ZMUser.selfUser(in: self.userSession!.syncManagedObjectContext).selfClient()!
        var prekey: String?
        self.encryptionContext(for: client).perform { (session) in
            prekey = try! session.generateLastPrekey()
        }

        selfClient.keysStore.encryptionContext.perform { (session) in
            try! session.createClientSession(client.sessionIdentifier!, base64PreKeyString: prekey!)
        }
    }

    /// Creates a session between the self client, and a client matching a remote client.
    /// If no such client exists locally, it creates it (and the user associated with it).
    public func establishSessionFromSelf(toRemote remoteClient: MockUserClient) {

        guard let remoteUserIdentifierString = remoteClient.user?.identifier,
            let remoteUserIdentifier = UUID(uuidString: remoteUserIdentifierString),
            let remoteClientIdentifier = remoteClient.identifier else {
                fatalError("You should set up remote client with user and identifier")
        }

        // create user

        let localUser = ZMUser.fetchOrCreate(with: remoteUserIdentifier, domain: nil, in: userSession!.syncManagedObjectContext)

        // create client
        let localClient = localUser.clients.first(where: { $0.remoteIdentifier == remoteClientIdentifier }) ?? { () -> UserClient in
            let newClient = UserClient.insertNewObject(in: self.userSession!.syncManagedObjectContext)
            newClient.user = localUser
            newClient.remoteIdentifier = remoteClientIdentifier
            return newClient
            }()
        self.userSession!.syncManagedObjectContext.saveOrRollback()

        var lastPrekey: String?
        self.mockTransportSession.performRemoteChanges { (_) in
            lastPrekey = remoteClient.lastPrekey.value
        }

        let selfClient = ZMUser.selfUser(in: self.userSession!.syncManagedObjectContext).selfClient()!
        if !localClient.hasSessionWithSelfClient {
            XCTAssertTrue(selfClient.establishSessionWithClient(localClient, usingPreKey: lastPrekey!))
        }
    }

    /// Decrypts a message that was sent from self to a given user
    public func decryptMessageFromSelf(cypherText: Data, to client: UserClient) -> Data? {

        let selfClient = ZMUser.selfUser(in: self.userSession!.syncManagedObjectContext).selfClient()!
        var plainText: Data?
        self.encryptionContext(for: client).perform { (session) in
            if session.hasSession(for: selfClient.sessionIdentifier!) {
                do {
                    plainText = try session.decrypt(cypherText, from: selfClient.sessionIdentifier!)
                } catch {
                    XCTFail("Decryption error: \(error)")
                }
            } else {
                do {
                    plainText = try session.createClientSessionAndReturnPlaintext(for: selfClient.sessionIdentifier!, prekeyMessage: cypherText)
                } catch {
                    XCTFail("Decryption error: \(error)")
                }
            }
        }
        return plainText
    }
}

extension IntegrationTest {

    /// Delete all other clients encryption contexts
    public func deleteAllOtherEncryptionContexts() {
        try?  FileManager.default.removeItem(at: self.otherClientsEncryptionContextsURL)
    }

    /// Returns the folder where the encryption contexts for other test clients are stored
    var otherClientsEncryptionContextsURL: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("OtherClients")
    }

    /// Returns the encryption context to use for a given client. There are extra cryptobox sessions
    /// that simulate a remote client able to decrypt/encrypt data with its own cryptobox instance.
    /// If the client has no remote identifier, it will create one
    fileprivate func encryptionContext(for client: UserClient) -> EncryptionContext {
        if client.remoteIdentifier == nil {
            client.remoteIdentifier = NSString.createAlphanumerical() as String
        }
        let url =  self.otherClientsEncryptionContextsURL.appendingPathComponent("client-\(client.remoteIdentifier!)")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        let encryptionContext = EncryptionContext(path: url)
        return encryptionContext
    }
}
