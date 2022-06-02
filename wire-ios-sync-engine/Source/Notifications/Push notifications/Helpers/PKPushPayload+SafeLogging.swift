////
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

import Foundation
import PushKit

extension PKPushPayload: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        // The structure of APS payload is like this:
        //  {
        //      "aps" : {},
        //      "data" : {
        //          "data" : {
        //              "id" : "e919a0df-8e56-11e9-8123-22111a62954d",
        //          }
        //          "type" : "notice",
        //          "user" : "1a62954d-8123-11e9-8e56-2211e919a0df"
        //      }
        //  }
        let data = dictionaryPayload["data"] as? [String: Any]
        let payloadData = data?["data"] as? [String: String]
        let payloadID = payloadData?["id"]?.readableHash ?? "n/a"
        let userID = (data?["user"] as? String)?.readableHash ?? "n/a"
        return "id=\(payloadID) user=\(userID)"
    }
}
