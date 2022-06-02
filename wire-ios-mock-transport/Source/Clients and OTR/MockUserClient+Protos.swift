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

import Foundation
import WireProtos

public protocol OtrMessage {
    var sender: Proteus_ClientId { get }
}

extension MockUserClient {
    
    /// Returns an OTR message with the recipients correctly set
    /// - Parameters:
    ///   - clients: clients needed to create recipients
    ///   - plainText: plain text
    /// - Returns: OTR message
    public func newOtrMessageWithRecipients(for clients: [MockUserClient], plainText: Data) -> Proteus_NewOtrMessage {
        let sender = Proteus_ClientId.with {
            $0.client = identifier!.asHexEncodedUInt
        }
        let message = Proteus_NewOtrMessage.with {
            $0.sender = sender
            $0.recipients = userEntries(for: clients, plainText: plainText)
        }
        return message
    }
    
    /// Returns an OTR asset message builder with the recipients correctly set
    /// - Parameters:
    ///   - clients: clients needed to create recipients
    ///   - plainText: plain text
    /// - Returns: OTR asset message
    public func otrAssetMessageBuilderWithRecipients(for clients: [MockUserClient], plainText: Data) -> Proteus_OtrAssetMeta {
        
        var message = Proteus_OtrAssetMeta()
        var sender = Proteus_ClientId()
        
        sender.client = identifier!.asHexEncodedUInt
        message.sender = sender
        message.recipients = userEntries(for: clients, plainText: plainText)

        return message
    }
    
    /// Create user entries for all received of a message
    private func userEntries(for clients: [MockUserClient], plainText: Data) -> [Proteus_UserEntry] {
        return MockUserClient.createUserToClientMapping(for: clients).map { (user: MockUser, clients: [MockUserClient]) -> Proteus_UserEntry in
            
            let clientEntries = clients.map { client -> Proteus_ClientEntry in
                let clientId = Proteus_ClientId.with {
                    $0.client = client.identifier!.asHexEncodedUInt
                }
                return Proteus_ClientEntry.with {
                    $0.client = clientId
                    $0.text = MockUserClient.encrypted(data: plainText, from: self, to: client)
                }
            }
            
            let userId = Proteus_UserId.with {
                $0.uuid = UUID(uuidString: user.identifier)!.uuidData
            }
            
            return Proteus_UserEntry.with {
                $0.user = userId
                $0.clients = clientEntries
            }
        }
    }
    
    /// Map a list of clients to a lookup by user
    static private func createUserToClientMapping(for clients: [MockUserClient]) -> [MockUser: [MockUserClient]]{
        var mapped = [MockUser: [MockUserClient]]()
        clients.forEach { client in
            var previous = mapped[client.user!] ?? [MockUserClient]()
            previous.append(client)
            mapped[client.user!] = previous
        }
        return mapped
    }
    
}

extension String {
    
    /// Parses the string as if it was a hex representation of a number
    fileprivate var asHexEncodedUInt: UInt64 {
        var scannedIdentifier: UInt64 = 0
        Scanner(string: self).scanHexInt64(&scannedIdentifier)
        return scannedIdentifier
    }
}

extension Proteus_NewOtrMessage: OtrMessage {}

extension Proteus_OtrAssetMeta: OtrMessage {}
