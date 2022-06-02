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
import UIKit

extension Data {
    /// return a lower case and space between every byte string of the given data
    var fingerprintString: String {
        let string = String(decoding: self, as: UTF8.self)

        return string.fingerprintStringWithSpaces
    }

    func attributedFingerprint(attributes: [NSAttributedString.Key: AnyObject], boldAttributes: [NSAttributedString.Key: AnyObject], uppercase: Bool = false) -> NSAttributedString? {

        var fingerprintString = self.fingerprintString

        if uppercase {
            fingerprintString = fingerprintString.uppercased()
        }

        let attributedRemoteIdentifier = fingerprintString.fingerprintString(attributes: attributes, boldAttributes: boldAttributes)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        return attributedRemoteIdentifier && [.paragraphStyle: paragraphStyle]
    }
}
