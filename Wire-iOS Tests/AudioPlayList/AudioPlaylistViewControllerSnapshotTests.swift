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

final class AudioPlaylistViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: AudioPlaylistViewController!
    
    override func setUp() {
        super.setUp()
        sut = AudioPlaylistViewController()
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 375)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForPlayListLoaded(){
        let image = self.image(inTestBundleNamed: "unsplash_square.jpg")

        let JSON = jsonObject(fromFile: "soundcloud-playlist1.json")
        let audioPlaylist = SoundcloudPlaylist.audioPlaylist(fromJSON: JSON, soundcloudService: nil)
        (audioPlaylist?.tracks.first as? SoundcloudAudioTrack)?.artwork = image
        (audioPlaylist?.tracks[1] as? SoundcloudAudioTrack)?.artwork = image

        sut.audioPlaylist = audioPlaylist

        sut.backgroundView.image = image
        sut.providerImage = image

        verify(view: sut.view)
    }
}
