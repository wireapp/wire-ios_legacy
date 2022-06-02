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

import Foundation

extension NSError {
    @objc public static var ZMUserSessionErrorDomain = "ZMUserSession"

    @objc(initWitUserSessionErrorWithErrorCode:userInfo:)
    public convenience init(code: ZMUserSessionErrorCode, userInfo: [String: Any]?) {
        var info = userInfo ?? [:]
        if let description = code.errorDescription {
            info[NSLocalizedDescriptionKey] = description
        }
        self.init(domain: NSError.ZMUserSessionErrorDomain, code: Int(code.rawValue), userInfo: info)
    }
}
