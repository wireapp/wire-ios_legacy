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
@testable import Wire

/// The App Delegate to use for the test target.

final class TestingAppDelegate: AppDelegate {

    // We don't want the self user to be automatically configured as it is in production code.
    // Explicit configuration (via `SelfUser.provider = someSelfUserProvider` ) helps clarify
    // mocking scenarios by asserting that the test writer provides the self user themselves.

    override var shouldConfigureSelfUserProvider: Bool {
        return false
    }

}
