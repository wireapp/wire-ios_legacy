//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

/// get version from Version.xcconfig
/// Example: $swift readVersion.swift ./Wire-iOS/Resources/Configuration/Version.xcconfig

import Foundation

//MARK: - main

var path: String!

if CommandLine.arguments.count == 2 {
    path = CommandLine.arguments[1]
} else {
    print("❌ exit: please provide Version.xcconfig path.\nExample: $swift readVersion.swift ./Wire-iOS/Resources/Configuration/Version.xcconfig")

    exit(1)
}

let versionXcconfigUrl = URL(fileURLWithPath: path)

var lines: [String] = []

do {
    let contents = try String(contentsOf: versionXcconfigUrl, encoding: String.Encoding.utf8)
    
    lines = contents.components(separatedBy: "\n")
    
} catch {
    print("❌ Error: \(error.localizedDescription)")
    exit(1)
}

var version: String?

lines.forEach() {
    let components:[String] = $0.components(separatedBy: " ")
    
    if components.count == 3 {
        
        let flag = components[0]
        if flag == "WIRE_SHORT_VERSION" {
            version = components[2]
        }
    }
}

print("\(version ?? "nil")")
