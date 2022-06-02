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

public extension NotificationDispatcher {

    /// Describes how the `NotificationDispatcher` should behave in relation to the
    /// expected work load (the number of database changes it must process).
    ///
    /// The normal operation mode is a relatively expensive operation and may cause
    /// a considerably large amount of observer code to be triggered. If several
    /// changes are made to the database, you may wish to switch to the `econmical` mode.

    enum OperationMode {

        /// Change detection is highly detailed and observers are notified frequently.

        case normal

        /// Change detection is minimal and observers are notified infrequently.

        case economical

    }

}
