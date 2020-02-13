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

import XCTest
@testable import Wire

final class String_FingerprintTests: XCTestCase {
    func testFingerprintAttributes() {
        let regularAttributes = [
                                 NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
                                 ]
        let boldAttributes = [
                              NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
                              ]
        let attributedString = fingerprintString.fingerprintString(attributes: regularAttributes, boldAttributes: boldAttributes)

        var bold = true
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: [], using: { attrs, range, stop in
            let stringInRange = ((attributedString.string as NSString?)?.substring(with: range))?.trimmingCharacters(in: CharacterSet.whitespaces)
            if (stringInRange?.count ?? 0) == 0 {
                return
            }
            XCTAssertEqual(attrs as? [NSAttributedString.Key: UIFont], bold ? boldAttributes : regularAttributes)
            bold = !bold
        })
    }

    // MARK: - Helper
    var fingerprintString: String {
        return "05 1c f4 ca 74 4b 80"
    }

}
