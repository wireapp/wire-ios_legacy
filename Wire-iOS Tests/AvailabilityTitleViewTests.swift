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

class AvailabilityTitleViewTests: ZMSnapshotTestCase {
    
    var selfUser: ZMUser!
    var otherUser: ZMUser?
    
    override func setUp() {
        super.setUp()
        otherUser = ZMUser.insertNewObject(in: self.uiMOC)
        otherUser?.name = "Giovanni"
        selfUser = ZMUser.selfUser()
    }
    
    override func tearDown() {
        selfUser = nil
        otherUser = nil
        super.tearDown()
    }
    
    // MARK: - Self Profile
    
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
        createTest(for: .profileDetails, with: .none, on: otherUser!, colorSchemeVariant: .light)
    }
    
    func testThatItRendersCorrectly_OtherProfile_AvailableAvailability() {
        createTest(for: .profileDetails, with: .available, on: otherUser!, colorSchemeVariant: .light)
    }
    
    func testThatItRendersCorrectly_OtherProfile_AwayAvailability() {
        createTest(for: .profileDetails, with: .away, on: otherUser!, colorSchemeVariant: .light)
    }
    
    func testThatItRendersCorrectly_OtherProfile_BusyAvailability() {
        createTest(for: .profileDetails, with: .busy, on: otherUser!, colorSchemeVariant: .light)
    }
    
    // MARK: - Common methods
    
    private func createTest(for options: AvailabilityTitleView.Options, with availability: Availability, on user: ZMUser, colorSchemeVariant: ColorSchemeVariant = .dark, file: StaticString = #file, line: UInt = #line) {
        updateAvailability(for: user, newValue: availability)
        let sut = AvailabilityTitleView(user: user, options: options)
        sut.colorSchemeVariant = colorSchemeVariant
        sut.backgroundColor = colorSchemeVariant == .light ? .white : .black
        verify(view: sut, file: file, line: line)
    }
    
    func updateAvailability(for user: ZMUser, newValue: Availability) {
        if user == ZMUser.selfUser() {
            user.availability = newValue
        } else {
            // if the user is not self, force the update of the availability
            user.updateAvailability(newValue)
        }
    }
    
}

extension ZMUser {
    internal func updateAvailability(_ newValue : Availability) {
        self.willChangeValue(forKey: AvailabilityKey)
        self.setPrimitiveValue(NSNumber(value: newValue.rawValue), forKey: AvailabilityKey)
        self.didChangeValue(forKey: AvailabilityKey)
    }
}
