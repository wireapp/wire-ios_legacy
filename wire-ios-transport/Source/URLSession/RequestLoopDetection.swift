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

/// Records the URLs of REST requests sent over the network
@objc protocol RequestRecorder : NSObjectProtocol {
    
    /// Records a REST request
    func recordRequest(path: String, contentHash: UInt, date: Date?)
    
}

/// Monitors the REST requests that are sent over the network
/// to detect suspicious request loops
@objcMembers public class RequestLoopDetection : NSObject {
    
    /// List of requests
    fileprivate var recordedRequests : [IdentifierDate] = []
    
    /// After this time, requests are purged from the list
    static let decayTimer : TimeInterval = 60 // 1 minute
    
    /// Repeatition warning trigger threshold
    /// If a request is repeated more than this number of times,
    /// it will trigger a warning
    static let repetitionTriggerThreshold = 20
    
    /// Hard limit of URLs to keep in the history
    static let historyLimit = 120
    
    /// Trigger that will be invoked when a loop is detected
    /// The URL passed is the URL that created the loop
    fileprivate let triggerCallback : (String) -> (Void)
    
    public init(triggerCallback: @escaping (String)->(Void)) {
        self.triggerCallback = triggerCallback
    }
}

// MARK: - Loop detection
extension RequestLoopDetection : RequestRecorder{
    
    /// Resets the detector, discarding all recorder requests
    public func reset() {
        self.recordedRequests = []
    }
    
    public func recordRequest(path: String, contentHash: UInt, date: Date?) {
        purgeOldRequests()
        if self.recordedRequests.count == type(of: self).historyLimit {
            self.recordedRequests.remove(at: 0) // note, this would be more efficient with linked list
        }
        let identifier = IdentifierDate(path: path, contentHash: contentHash, date: date ?? Date())
        self.insert(identifier: identifier)
        triggerIfTooMany(identifier: identifier)
    }
    
    /// Removes requests that are too old from the recorded requests
    private func purgeOldRequests() {
        let purgeDate = Date(timeIntervalSinceNow: -type(of: self).decayTimer)
        if let firstNonTooOldIndex = self.recordedRequests.firstIndex(where: {
            $0.date > purgeDate
        }) {
            self.recordedRequests.removeFirst(firstNonTooOldIndex) // note, this would be more efficient with linked list
        } else {
            // all requests are old, kill them
            reset()
        }
    }
    
    /// Insert request in the right date order in the array.
    /// - note: Complexity: O(n). Could be made O(log(n)) with
    /// binary search
    private func insert(identifier: IdentifierDate) {
        if identifier.date.timeIntervalSinceNow < -type(of: self).decayTimer {
            return // not even adding, this is too old
        }
        
        // I assume most (if not all) request are inserted in ascending order, so I will
        // search backwards
        var insertionIndex = 0
        for i in (0..<self.recordedRequests.count).lazy.reversed() {
            if self.recordedRequests[i].date < identifier.date {
                insertionIndex = i+1
                break
            }
        }
        self.recordedRequests.insert(identifier, at: insertionIndex)
    }
    
    /// Check if there are too many occurrences of a given identifier
    private func triggerIfTooMany(identifier: IdentifierDate) {
        if self.recordedRequests
            .filter({ $0.identifier == identifier.identifier })
            .count >= type(of: self).repetitionTriggerThreshold {
            // this could be slightly faster as we don't need to count, just stop after we found N
            // (maybe there are N+1000 entries and we don't need to go through the additional 1000)
            self.triggerCallback(identifier.path)
            self.recordedRequests = self.recordedRequests.filter { $0.identifier != identifier.identifier }
        }
    }
}


fileprivate struct IdentifierDate {
    let identifier : String
    let date : Date
    let path : String
    
    init(path: String, contentHash: UInt, date: Date) {
        self.identifier = "\(path)[\(contentHash)]"
        self.date = date
        self.path = path
    }
}

