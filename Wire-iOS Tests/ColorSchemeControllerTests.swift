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
    var originalColorScheme: Any! = nil
    var originalVariant: ColorSchemeVariant!


    override func setUp() {
        super.setUp()

        sut = ColorSchemeController()
        if originalColorScheme == nil {
            originalColorScheme = UserDefaults.standard.value(forKey: SettingKey.colorScheme.rawValue)
        }

        if originalVariant == nil {
            originalVariant = ColorScheme.default.variant
        }
    }

    override func tearDown() {
        sut = nil
        UserDefaults.standard.set(originalColorScheme, forKey: SettingKey.colorScheme.rawValue)
        ColorScheme.default.variant = originalVariant
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
        super.tearDown()
    }


    func testThatColorSchemeIsUpdatedAfterSettingIsChanged(){
        // GIVEN
        let colorScheme = ColorScheme.default

        // WHEN
        setToLightTheme()

        // THEN
        XCTAssertEqual(colorScheme.variant, .light)

        // WHEN
        UserDefaults.standard.set("dark", forKey: SettingKey.colorScheme.rawValue)
        NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: self)

        // THEN
        XCTAssertEqual(colorScheme.variant, .dark)
    }
}

extension XCTestCase {
    func setToLightTheme() {
        UserDefaults.standard.set("light", forKey: SettingKey.colorScheme.rawValue)
        NotificationCenter.default.post(name: .SettingsColorSchemeChanged, object: nil)
    }
}
