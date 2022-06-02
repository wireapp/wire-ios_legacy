import Foundation

// 1) Generate the Header

let year = Calendar.current.component(.year, from: Date())

let header = """
//
// Wire
// Copyright (C) \(year) Wire Swiss GmbH
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
//\n\n
"""

// 2) Insert into File

guard CommandLine.arguments.count >= 2 else {
    print("Please pass the path to file that needs a header.")
    exit(-1)
}

let fileURL = URL(fileURLWithPath: CommandLine.arguments[1])

let headerData = Data(header.utf8)
var fileData = try Data(contentsOf: fileURL)
fileData.insert(contentsOf: headerData, at: 0)
try fileData.write(to: fileURL)
