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

public typealias FileInDirectory = (FileManager.SearchPathDirectory, String)

public extension URL {

    public func wr_excludeFromBackup() throws {
        var mutableCopy = self
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try mutableCopy.setResourceValues(resourceValues)
    }

    public static func wr_directory(for searchPathDirectory: FileManager.SearchPathDirectory) -> URL {
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(searchPathDirectory, .userDomainMask, true).first!)
    }

}
