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

final class ColorSchemeControllerTests: XCTestCase {
    
    var sut: ColorSchemeController!
    var oriScheme: Any!
    override func setUp() {
        super.setUp()
        sut = ColorSchemeController()

        oriScheme = UserDefaults.standard.value(forKey: UserDefaultColorScheme)
    }
    
    override func tearDown() {
        sut = nil
        UserDefaults.standard.set(oriScheme, forKey: UserDefaultColorScheme)
        super.tearDown()
    }


    func testThatColorSchemeIsUpdatedAfterSettingIsChanged(){
        // GIVEN
        let colorScheme = ColorScheme.default

        // WHEN
        UserDefaults.standard.set("light", forKey: UserDefaultColorScheme)
        NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: self)

        // THEN
        XCTAssertEqual(colorScheme.variant, .light)

        // WHEN
        UserDefaults.standard.set("dark", forKey: UserDefaultColorScheme)
        NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: self)

        // THEN
        XCTAssertEqual(colorScheme.variant, .dark)
    }
}
