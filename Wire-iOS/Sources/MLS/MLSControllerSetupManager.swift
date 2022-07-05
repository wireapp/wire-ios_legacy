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
import WireSyncEngine
import WireCoreCrypto

class MLSControllerSetupManager {

    weak var configurationProvider: CoreCryptoConfigurationProvider?
    weak var mlsControllerInitializerHelper: MLSControllerInitializerHelper?

    init(sessionManager: CoreCryptoConfigurationProvider & MLSControllerInitializerHelper) {
        self.configurationProvider = sessionManager
        self.mlsControllerInitializerHelper = sessionManager
    }

    func setUpMLSControllerIfNeeded() {
        guard
            let mlsControllerInitializerHelper = mlsControllerInitializerHelper,
            !mlsControllerInitializerHelper.isMLSControllerInitialized,
            let configuration = configurationProvider?.coreCryptoConfiguration
        else {
            return
        }

        do {
            let coreCrypto = try CoreCrypto(
                path: configuration.path,
                key: configuration.key,
                clientId: configuration.clientId
            )

            mlsControllerInitializerHelper.initializeMLSController(coreCrypto: coreCrypto)

        } catch {
            // TODO: error handling
            fatalError(String(describing: error))
        }
    }

}
