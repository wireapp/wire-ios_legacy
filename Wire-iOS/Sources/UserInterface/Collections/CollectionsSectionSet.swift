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


/// This option set represents the collection sections.
public struct CollectionsSectionSet: OptionSet, Hashable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public init?(index: UInt) {
        self = type(of: self).visible[Int(index)]
    }
    
    public static let none = CollectionsSectionSet(rawValue: 0)
    public static let images = CollectionsSectionSet(rawValue: 1)
    public static let filesAndAudio = CollectionsSectionSet(rawValue: 1 << 1)
    public static let videos = CollectionsSectionSet(rawValue: 1 << 2)
    public static let links = CollectionsSectionSet(rawValue: 1 << 3)
    public static let loading = CollectionsSectionSet(rawValue: 1 << 4) // special section that shows the loading view
    
    /// Returns all possible section types
    public static let all: CollectionsSectionSet = [.images, .filesAndAudio, .videos, .links, .loading]
    
    /// Returns visible sections in the display order
    public static let visible: [CollectionsSectionSet] = [images, videos, links, filesAndAudio, loading]
}
