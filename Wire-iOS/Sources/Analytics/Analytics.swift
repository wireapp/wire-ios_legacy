//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class Analytics: NSObject {
    
    var provider: AnalyticsProvider?

    private static let sharedAnalytics = Analytics()
    
    @objc
    class func shared() -> Analytics {
        return sharedAnalytics
    }

    class func loadShared(withOptedOut optedOut: Bool) {
        //no-op
    }
    
    override init() {
        //no-op
    }
    
    required init(optedOut: Bool) {
        //no-op
    }
    
    func setTeam(_ team: Team?) {
        //no-op
    }
    
    func tagEvent(_ event: String, attributes: [String : Any]) {
        guard let attributes = attributes as? [String : NSObject] else { return }
        
        tagEvent(event, attributes: attributes)
    }

    //MARK: - OTREvents
    func tagCannotDecryptMessage(withAttributes userInfo: [AnyHashable : Any]?) {
        //no-op
    }
}

extension Analytics: AnalyticsType {
    @objc(setPersistedAttributes:forEvent:) func setPersistedAttributes(_ attributes: [String : NSObject]?, for event: String) {
        //no-op
    }
    
    @objc(persistedAttributesForEvent:) func persistedAttributes(for event: String) -> [String : NSObject]? {
        //no-op
        return nil
    }
    
    /// Record an event with no attributes
    func tagEvent(_ event: String) {
        //no-op
    }
    
    /// Record an event with optional attributes.
    func tagEvent(_ event: String, attributes: [String : NSObject]) {
        //no-op
    }
}
