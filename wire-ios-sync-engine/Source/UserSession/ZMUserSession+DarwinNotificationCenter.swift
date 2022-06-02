//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireUtilities

@objc extension ZMUserSession {
    /// Listens and reacts to hints from the share extension that the user
    /// session should try to merge changes to its managed object contexts.
    /// This ensures that the UI is up to date when the share extension has
    /// been invoked while the app is active.
    public func observeChangesOnShareExtension() {
        DarwinNotificationCenter.shared.observe(notification: .shareExtDidSaveNote) { [weak self] () in
            self?.mergeChangesFromStoredSaveNotificationsIfNeeded()
        }
    }
}
