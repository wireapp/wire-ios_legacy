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

import XCTest
@testable import Wire

extension XCTestCase {
    func jsonObject(fromFile file: String) -> [AnyHashable : Any]? {
        let url = urlForResource(inTestBundleNamed: file)

        var JSON: [AnyHashable : Any]? = nil

        if let data = NSData(contentsOf: url) {
            do {
                JSON = try JSONSerialization.jsonObject(with: data as Data, options: []) as? [AnyHashable : Any]
            } catch {
                XCTFail("Error parsing JSON: \(error)")
            }
        }

        return JSON
    }

    func audioTrackFromJSON(filename: String) -> SoundcloudAudioTrack? {
        let JSON = jsonObject(fromFile: filename)
        let audioTrack = SoundcloudAudioTrack(fromJSON: JSON, soundcloudService: nil)

        return audioTrack
    }
}

