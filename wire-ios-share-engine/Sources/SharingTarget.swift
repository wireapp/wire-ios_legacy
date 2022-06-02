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
import WireDataModel

/// A target of sharing content
public protocol SharingTarget {

    /// Appends a text message in the conversation
    func appendTextMessage(_ message: String, fetchLinkPreview: Bool) -> Sendable?

    /// Appends an image in the conversation
    func appendImage(_ data: Data) -> Sendable?

    /// Appends a file in the conversation
    func appendFile(_ metaData: ZMFileMetadata) -> Sendable?

    /// Append a location in the conversation
    func appendLocation(_ location: LocationData) -> Sendable?
}
