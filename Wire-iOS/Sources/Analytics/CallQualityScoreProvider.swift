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

final class CallQualityScoreProvider: NSObject, AnalyticsType {
    public static let shared = CallQualityScoreProvider()
    
    private var lastCallingEvent: [String: NSObject] = [:]

    func recordCallQualityReview(_ review: CallQualitySurveyReview) {

        var attributes = lastCallingEvent
        attributes["action"] = review.label
        attributes["score"] = review.score
        attributes["duration"] = review.callDuration
        attributes["reason"] = review.reason

        nextProvider?.tagEvent(type(of: self).callingEventName, attributes: attributes)
    }

    private static let callingEventName = "calling.call_quality_review"
    
    public var nextProvider: AnalyticsType? = nil
    
    public func tagEvent(_ event: String) {
        self.tagEvent(event, attributes: [:])
    }
    
    public func tagEvent(_ event: String, attributes: [String : NSObject]) {
        DispatchQueue.main.async {
            if event == type(of: self).callingEventName {
                self.lastCallingEvent = attributes
            }
            else {
                self.nextProvider?.tagEvent(event, attributes: attributes)
            }
        }
    }

    func setPersistedAttributes(_ attributes: [String : NSObject]?, for event: String) {
        nextProvider?.setPersistedAttributes(attributes, for: event)
    }

    func persistedAttributes(for event: String) -> [String : NSObject]? {
        return nextProvider?.persistedAttributes(for: event)
    }
}

// MARK: - Survey Mute Filter

let UserDefaultLastCallSurveyDate = "LastCallSurveyDate"
let CallSurveyMuteInterval: TimeInterval = Calendar.secondsInDays(10)

extension CallQualityScoreProvider {

    static func updateLastSurveyDate(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSinceReferenceDate, forKey: UserDefaultLastCallSurveyDate)
    }

    static func resetSurveyMuteFilter() {
        UserDefaults.standard.removeObject(forKey: UserDefaultLastCallSurveyDate)
    }
    
    static func canRequestSurvey(at date: Date, muteInterval: TimeInterval = CallSurveyMuteInterval) -> Bool {
        
        let lastSurveyTimestamp = UserDefaults.standard.double(forKey: UserDefaultLastCallSurveyDate)
        let lastSurveyDate = Date(timeIntervalSinceReferenceDate: lastSurveyTimestamp)
        let nextPossibleDate = lastSurveyDate.addingTimeInterval(muteInterval)
                
        // Allow the survey if the mute period is finished
        return (date >= nextPossibleDate)
        
    }
    
}
