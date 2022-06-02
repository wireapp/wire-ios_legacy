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
import WireCryptobox

/// sample client ID
let hardcodedClientId = EncryptionSessionIdentifier(domain: "example.com", userId: "1e9b4e18", clientId: "7a9eb715")

/// sample prekey
let hardcodedPrekey = "pQABAQUCoQBYIEIir0myj5MJTvs19t585RfVi1dtmL2nJsImTaNXszRwA6EAoQBYIGpa1sQFpCugwFJRfD18d9+TNJN2ZL3H0Mfj/0qZw0ruBPY="

/// Creates a temporary folder and returns its URL
func createTempFolder() -> URL {
    let url = URL(fileURLWithPath: [NSTemporaryDirectory(), UUID().uuidString].joined(separator: "/"))
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
    return url
}

func createEncryptionContext() -> EncryptionContext {
    let folder = createTempFolder()
    return EncryptionContext(path: folder)
}
