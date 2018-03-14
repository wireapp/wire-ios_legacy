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

import Foundation

enum CallQualitySurveyReview {

    case notDisplayed(reason: IgnoreReason, duration: Int)
    case answered(score: Int, duration: Int)
    case dismissed(duration: Int)

    enum IgnoreReason: String {
        case callTooShort = "call-too-short"
        case callFailed = "call-failed"
        case muted = "muted"
    }

    var label: NSString {
        switch self {
        case .notDisplayed: return "not-displayed"
        case .answered: return "answered"
        case .dismissed: return "dismissed"
        }
    }

    var score: NSNumber? {
        switch self {
        case .answered(let score, _): return score as NSNumber
        default: return nil
        }

    }

    var callDuration: NSNumber {
        switch self {
        case .notDisplayed(_, let duration): return duration as NSNumber
        case .answered(_, let duration): return duration as NSNumber
        case .dismissed(let duration): return duration as NSNumber
        }
    }

    var reason: NSString? {
        switch self {
        case .notDisplayed(let reason, _): return reason.rawValue as NSString
        default: return nil
        }
    }

}
