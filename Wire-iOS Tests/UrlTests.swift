//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class UrlTests: XCTestCase {
    func testForFingerprintLearnMoreURL(){
        let sut = NSURL.wr_fingerprintLearnMoreURL

        XCTAssertEqual(sut.absoluteString, "https://wire.com/privacy/why")
    }

    func testForWireAppOnItunes(){
        let sut = URL.wr_wireAppOnItunes

        XCTAssertEqual(sut.absoluteString, "https://geo.itunes.apple.com/us/app/wire/id930944768?mt=8")
    }

    func testForRandomProfilePictureSource(){
        let sut = URL.wr_randomProfilePictureSource

        XCTAssertEqual(sut.absoluteString, "https://source.unsplash.com/800x800/?landscape")
    }

    func testForTermsOfServicesURLForTeam(){
        let sut = URL.wr_termsOfServicesURL(forTeamAccount: true)

        XCTAssertEqual(sut.absoluteString, "https://wire.com/legal/terms/teams")
    }

    func testForTermsOfServicesURLForPersonal(){
        let sut = URL.wr_termsOfServicesURL(forTeamAccount: false)

        XCTAssertEqual(sut.absoluteString, "https://wire.com/legal/terms/personal")
    }

    func testForManageTeamOnboarding(){
        let sut = URL.manageTeam(source: .onboarding)

        XCTAssertEqual(sut.absoluteString, "https://teams.wire.com/login?utm_source=client_landing&utm_term=ios&hl=en_US")
    }

    func testForManageTeamSettings(){
        let sut = URL.manageTeam(source: .settings)

        XCTAssertEqual(sut.absoluteString, "https://teams.wire.com/login?utm_source=client_settings&utm_term=ios&hl=en_US")
    }
}
