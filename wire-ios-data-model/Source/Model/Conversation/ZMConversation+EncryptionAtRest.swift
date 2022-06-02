//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMConversation: EncryptionAtRestMigratable {

    static let predicateForObjectsNeedingMigration: NSPredicate? =
        NSPredicate(format: "%K != nil", #keyPath(ZMConversation.draftMessageData))

    func migrateTowardEncryptionAtRest(in moc: NSManagedObjectContext) throws {
        guard let data = draftMessageData else { return }
        let (ciphertext, nonce) = try moc.encryptData(data: data)
        draftMessageData = ciphertext
        draftMessageNonce = nonce
    }

    func migrateAwayFromEncryptionAtRest(in moc: NSManagedObjectContext) throws {
        guard
            let data = draftMessageData,
            let nonce = draftMessageNonce
        else {
            return
        }

        let plaintext = try moc.decryptData(data: data, nonce: nonce)
        draftMessageData = plaintext
        draftMessageNonce = nil
    }

}
