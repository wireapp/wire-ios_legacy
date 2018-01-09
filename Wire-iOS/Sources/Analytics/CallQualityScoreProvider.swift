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
    public var userScore: RatingState? = nil {
        didSet {
            guard let userScore = self.userScore, let rating1 = userScore.rating1, let rating2 = userScore.rating2 else {
                return
            }
            
            var attributes = lastCallingEvent
            attributes["score1"] = NSNumber(integerLiteral: rating1)
            attributes["score2"] = NSNumber(integerLiteral: rating2)
            nextProvider?.tagEvent(type(of: self).callingEventName, attributes: attributes)
            self.userScore = nil
        }
    }
    
    private static let callingEventName = "calling.avs_metrics_ended_call"
    
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
}
