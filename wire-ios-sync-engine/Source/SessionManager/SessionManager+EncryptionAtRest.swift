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

extension SessionManager: UserSessionEncryptionAtRestDelegate {

    func setEncryptionAtRest(enabled: Bool, account: Account, encryptionKeys: EncryptionKeys) {
        let sharedContainerURL = self.sharedContainerURL
        let dispatchGroup = self.dispatchGroup

        delegate?.sessionManagerWillMigrateAccount(userSessionCanBeTornDown: { [weak self] in
            self?.tearDownBackgroundSession(for: account.userIdentifier)
            self?.activeUserSession = nil
            CoreDataStack.migrateLocalStorage(accountIdentifier: account.userIdentifier,
                                             applicationContainer: sharedContainerURL,
                                             dispatchGroup: dispatchGroup,
                                             migration: { context in
                                                if enabled {
                                                    try context.enableEncryptionAtRest(encryptionKeys: encryptionKeys)
                                                } else {
                                                    try context.disableEncryptionAtRest(encryptionKeys: encryptionKeys)
                                                    try EncryptionKeys.deleteKeys(for: account)
                                                }
            }, completion: { result in
                switch result {
                case .success:
                    self?.loadSession(for: account, completion: { _ in })
                case .failure(let error):
                    Logging.EAR.debug("Failed to migrate account: \(error)")
                }
            })
        })
    }

}
