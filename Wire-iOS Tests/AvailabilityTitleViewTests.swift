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

import XCTest
@testable import Wire
import Classy
import Cartography

class AvailabilityTitleViewTests: CoreDataSnapshotTestCase {

    var sut: AvailabilityTitleView?
    
    override func setUp() {
        super.setUp()
    }

    // MARK: – Setup
    
    private func setAvailability(availability: Availability, for user: ZMUser) {
        user.availability = availability
        moc.saveOrRollback()
    }
    
    // MARK: - Self profile
    
    func testThatItRendersCorrectly_SelfProfile_NoneAvailability() {
        createTest(for: .selfProfile, with: .none, on: selfUser)
    }
    
    func testThatItRendersCorrectly_SelfProfile_AvailableAvailability() {
        createTest(for: .selfProfile, with: .available, on: selfUser)
    }
    
    func testThatItRendersCorrectly_SelfProfile_AwayAvailability() {
        createTest(for: .selfProfile, with: .away, on: selfUser)
    }
    
    func testThatItRendersCorrectly_SelfProfile_BusyAvailability() {
        createTest(for: .selfProfile, with: .busy, on: selfUser)
    }
    
    // MARK: - Headers profile
    
    func testThatItRendersCorrectly_Header_NoneAvailability() {
        createTest(for: .header, with: .none, on: selfUser)
    }
    
    func testThatItRendersCorrectly_Header_AvailableAvailability() {
        createTest(for: .header, with: .available, on: selfUser)
    }
    
    func testThatItRendersCorrectly_Header_AwayAvailability() {
        createTest(for: .header, with: .away, on: selfUser)
    }
    
    func testThatItRendersCorrectly_Header_BusyAvailability() {
        createTest(for: .header, with: .busy, on: selfUser)
    }
    
    // MARK: - Other profile
    
    func testThatItRendersCorrectly_OtherProfile_NoneAvailability() {
        createTest(for: .otherProfile, with: .none, on: selfUser)
    }
    
    func testThatItRendersCorrectly_OtherProfile_AvailableAvailability() {
        createTest(for: .otherProfile, with: .available, on: selfUser)
    }
    
    func testThatItRendersCorrectly_OtherProfile_AwayAvailability() {
        createTest(for: .otherProfile, with: .away, on: selfUser)
    }
    
    func testThatItRendersCorrectly_OtherProfile_BusyAvailability() {
        createTest(for: .otherProfile, with: .busy, on: selfUser)
    }
    
    // MARK: - Common methods
    
    private func createTest(for style: AvailabilityTitleViewStyle, with availability: Availability, on user: ZMUser) {
        setAvailability(availability: availability, for: user)
        self.sut = AvailabilityTitleView(user: user, style: style)
        guard let sut = self.sut else { XCTFail(); return }
        sut.configure(context: moc)
        
        switch style {
            case .header, .selfProfile:     sut.backgroundColor = .black
            case .otherProfile:             sut.backgroundColor = .white
        }
        verify(view: sut)
    }
    
    
    
}

