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

let UserDefaultLastCallSurveyDate = "LastCallSurveyDate"
let CallSurveyMuteInterval: TimeInterval = Calendar.secondsInDays(10)

extension CallQualityController {

    /// Updates the date when the survey was last shown.
    static func updateLastSurveyDate(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSinceReferenceDate, forKey: UserDefaultLastCallSurveyDate)
    }

    /// Manually resets the mute survey filter.
    static func resetSurveyMuteFilter() {
        UserDefaults.standard.removeObject(forKey: UserDefaultLastCallSurveyDate)
    }

    /// Returns whether new call quality surveys can be requested, or if the user budget is exceeded.
    func canRequestSurvey(at date: Date, muteInterval: TimeInterval = CallSurveyMuteInterval) -> Bool {
        guard self.usesCallSurveyBudget else {
            return true
        }

        let lastSurveyTimestamp = UserDefaults.standard.double(forKey: UserDefaultLastCallSurveyDate)
        let lastSurveyDate = Date(timeIntervalSinceReferenceDate: lastSurveyTimestamp)
        let nextPossibleDate = lastSurveyDate.addingTimeInterval(muteInterval)
                
        // Allow the survey if the mute period is finished
        return (date >= nextPossibleDate)
    }
    
}
