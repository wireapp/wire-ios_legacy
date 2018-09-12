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

/**
 * User review for call quality.
 */

enum CallQualitySurveyReview {

    /// The survey was not displayed.
    case notDisplayed(reason: IgnoreReason, duration: Int)

    /// The survey was answered by the user.
    case answered(score: Int, duration: Int)

    /// The survey was dismissed.
    case dismissed(duration: Int)

    enum IgnoreReason: String {
        case callTooShort = "call-too-short"
        case muted = "muted"
    }

    // MARK: - Attributes

    /// The label of the review.
    var label: NSString {
        switch self {
        case .notDisplayed: return "not-displayed"
        case .answered: return "answered"
        case .dismissed: return "dismissed"
        }
    }

    /// The score provided by the user.
    var score: NSNumber? {
        switch self {
        case .answered(let score, _): return score as NSNumber
        default: return nil
        }
    }

    /// The duration of the call.
    var callDuration: NSNumber {
        switch self {
        case .notDisplayed(_, let duration): return duration as NSNumber
        case .answered(_, let duration): return duration as NSNumber
        case .dismissed(let duration): return duration as NSNumber
        }
    }

    /// The reason why the alert was not displayed.
    var ignoreReason: NSString? {
        switch self {
        case .notDisplayed(let reason, _): return reason.rawValue as NSString
        default: return nil
        }
    }

}
