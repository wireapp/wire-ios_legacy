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
import CoreData

@objc public class MockUserClient : NSManagedObject {
    
    /// User that owns the client
    @NSManaged public var user : MockUser?

    /// Remote identifier
    @NSManaged public var identifier : String?
    
    /// Device label
    @NSManaged public var label : String?
    
    /// Device type
    @NSManaged public var type : String?

    /// IP address of registration
    @NSManaged public var address : String?

    /// Device class
    @NSManaged public var deviceClass : String?
    
    /// Registration location latitude
    @NSManaged public var locationLatitude : Double

    /// Registration location longitude
    @NSManaged public var locationLongitude : Double
    
    /// Device model
    @NSManaged public var model : String?

    /// Time of registration
    @NSManaged public var time : Date?
    
    /// Encryption key for APS signalling
    @NSManaged public var enckey : String?
    
    /// Hashing key for APS signalling
    @NSManaged public var mackey : String?
    
    /// Prekeys registered for this client
    @NSManaged public var prekeys : Set<MockPreKey>
    
    /// Last prekeys registered for this client
    @NSManaged public var lastPrekey : MockPreKey

}

extension MockUserClient {

    /// Identifier for the session in Cryptobox
    public var sessionIdentifier : EncryptionSessionIdentifier? {
        guard let identifier = self.identifier, let userIdentifier = self.user?.identifier else {
            return nil
        }
        return EncryptionSessionIdentifier(userId: userIdentifier, clientId: identifier)
    }
  
    /// Returns a fetch request to fetch MockUserClients with the given predicate
    @objc public static func fetchRequest(predicate: NSPredicate) -> NSFetchRequest<MockUserClient> {
        let request = NSFetchRequest<MockUserClient>(entityName: "UserClient")
        request.predicate = predicate
        return request
    }
}

// MARK: - Legal Hold

extension MockUserClient {

    public var isLegalHoldDevice: Bool {
        return type == "legalhold" || deviceClass == "legalhold"
    }

}

// MARK: - JSON de/serialization
@objc extension MockUserClient {

    /// Creates a new client from JSON payload
    public static func insertClient(payload: [String:Any], context: NSManagedObjectContext) -> MockUserClient? {
        
        let label = payload["label"] as? String
        let deviceClass = payload["class"] as? String
        let model = payload["model"] as? String
        
        guard let type = payload["type"] as? String, validClientTypes.contains(type),
            let sigkeysPayload = payload["sigkeys"] as? [String: Any],
            let lastKeyPayload = payload["lastkey"] as? [String: Any],
            let prekeysPayload = payload["prekeys"] as? [[String: Any]],
            let mackey = sigkeysPayload["mackey"] as? String,
            let enckey = sigkeysPayload["enckey"] as? String,
            let prekeyNumber = lastKeyPayload["id"] as? Int, prekeyNumber == 0xFFFF
            else
        {
            return nil
        }
        
        let newClient = NSEntityDescription.insertNewObject(forEntityName: "UserClient", into: context) as! MockUserClient
        newClient.label = label
        newClient.type = type
        newClient.identifier = NSString.createAlphanumerical() as String
        newClient.mackey = mackey
        newClient.enckey = enckey
        newClient.deviceClass = deviceClass
        newClient.model = model
        newClient.locationLatitude = 52.5167
        newClient.locationLongitude = 13.3833
        newClient.address = "62.96.148.44"
        newClient.time = Date()
        
        let prekeys = MockPreKey.insertNewKeys(withPayload: prekeysPayload, context: context)
        prekeys.forEach {
            $0.client = newClient
        }

        let lastPreKey = MockPreKey.insertNewKey(withPayload: lastKeyPayload, context: context)!
        lastPreKey.client = newClient;
        
        newClient.prekeys = prekeys;
        newClient.lastPrekey = lastPreKey;
        
        
        return newClient;
    }
    
    /// Insert a new client, automatically generate prekeys and last key
    @objc(insertClientWithLabel:type:deviceClass:user:context:)
    public static func insertClient(label: String, type: String = "permanent", deviceClass: String = "phone", for user: MockUser, in context: NSManagedObjectContext) -> MockUserClient?
    {
        let newClient = NSEntityDescription.insertNewObject(forEntityName: "UserClient", into: context) as! MockUserClient

        newClient.user = user
        newClient.identifier = NSString.createAlphanumerical() as String
        newClient.label = label;
        newClient.type = type
        newClient.deviceClass = deviceClass
        newClient.time = Date()

        var generatedPrekeys : [[String: Any]]?
        var generatedLastPrekey : String?
        newClient.encryptionContext.perform { (session) in
            generatedPrekeys = try? session.generatePrekeys(NSMakeRange(0, 5))
            generatedLastPrekey = try? session.generateLastPrekey()
        }
        
        guard let prekeys = generatedPrekeys, !prekeys.isEmpty,
            let lastPrekey = generatedLastPrekey
        else {
            return nil
        }
        
        let mockPrekey = MockPreKey.insertNewKeys(withPayload: prekeys.map { $0["prekey"] as! String }, context: context)
        newClient.prekeys = Set(mockPrekey)
        
        let mockLastPrekey = MockPreKey.insertNewKey(withPrekey: lastPrekey, for: newClient, in: context)
        mockLastPrekey.identifier = Int(CBOX_LAST_PREKEY_ID)
        newClient.lastPrekey = mockLastPrekey;
        return newClient;
    }
    
    /// JSON representation
    public var transportData: ZMTransportData {
        
        var data = [String:Any]()
        data["id"] = self.identifier
        if self.label != nil {
            data["label"] = self.label
        }
        data["type"] = self.type
        if let time = self.time {
            data["time"] = time.transportString()
        }
        if let model = self.model {
            data["model"] = model
        }
        if let device = self.deviceClass {
            data["class"] = device
        }
        data["address"] = self.address
        data["location"] = [
            "lat" : self.locationLatitude,
            "lon" : self.locationLongitude
        ]
        return data as NSDictionary
    }
}

// MARK: - Encryption and sessions
@objc extension MockUserClient {

    @objc public static var mockEncryptionSessionDirectory: URL {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("mocktransport-encryptionDirectory")
    }

    static func encryptionContext(for user: MockUser?, clientId: String?) -> EncryptionContext {
        let directory = MockUserClient.mockEncryptionSessionDirectory
            .appendingPathComponent("mockclient_\(user?.identifier ?? "USER")_\(clientId ?? "IDENTIFIER")")
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [:])
        let encryptionContext = EncryptionContext(path: directory)
        return encryptionContext
    }

    fileprivate var encryptionContext: EncryptionContext {
        return MockUserClient.encryptionContext(for: user, clientId: identifier)
    }
    
    /// Make sure that there is a session established between this client and the given client
    /// If needed, it will use the last prekey to create a session
    /// - returns: false if it was not possible to establish a session
    public func establishSession(client: MockUserClient) -> Bool {
        guard let identifier = client.sessionIdentifier else { return false }
        var hasSession = false
        self.encryptionContext.perform { (session) in
            if !session.hasSession(for: identifier) {
                try? session.createClientSession(identifier, base64PreKeyString: client.lastPrekey.value)
                hasSession = session.hasSession(for: identifier)
            } else {
                hasSession = true
            }
        }
        return hasSession
    }
    
    /// Encrypt data from a client to a client. If there is no session between the two clients, it will create
    /// one using the last prekey
    public static func encrypted(data: Data, from: MockUserClient, to: MockUserClient) -> Data {
        var encryptedData: Data?
        guard from.establishSession(client: to) else { fatalError() }
        from.encryptionContext.perform { (session) in
            encryptedData = try? session.encrypt(data, for: to.sessionIdentifier!)
        }
        return encryptedData!
    }
    
    /// Decrypt a message (possibly establishing a session, if there is no session) from a client to a client
    public static func decryptMessage(data: Data, from: MockUserClient, to: MockUserClient) -> Data {
        var decryptedData: Data?
        to.encryptionContext.perform { (session) in
            if !session.hasSession(for: from.sessionIdentifier!) {
                decryptedData = try? session.createClientSessionAndReturnPlaintext(for: from.sessionIdentifier!, prekeyMessage: data)
            } else {
                decryptedData = try? session.decrypt(data, from: from.sessionIdentifier!)
            }
        }
        return decryptedData ?? Data()
    }
    
    /// Returns whether there is a encryption session between self and the give client
    public func hasSession(with client: MockUserClient) -> Bool {
        guard let identifier = client.sessionIdentifier else { return false }
        var hasSession = false
        self.encryptionContext.perform { (session) in
            hasSession = session.hasSession(for: identifier)
        }
        return hasSession
    }
}

/// Allowed client types
private let validClientTypes = Set(["temporary", "permanent", "legalhold"])

