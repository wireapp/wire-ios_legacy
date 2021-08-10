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
import WireDataModel

public extension AppLockController.LegacyConfig {

    private struct Container: Decodable {

        let legacyAppLockConfig: AppLockController.LegacyConfig?

    }

    static func fromBundle() -> Self? {
        guard
            let url = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            fatalError("session_manager.json not exist")
        }

        let container = try? JSONDecoder().decode(Container.self, from: data)
        return container?.legacyAppLockConfig
    }

}
