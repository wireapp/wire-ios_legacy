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
import CoreData
import WireSystem

private let zmLog = ZMSLog(tag: "Calling")

private let ZMVoiceChannelTimerTimeOutGroup: NSTimeInterval = 30
private let ZMVoiceChannelTimerTimeOutOneOnOne: NSTimeInterval = 60
private var ZMVoiceChannelTimerTestTimeout: NSTimeInterval = 0

private let UserInfoCallTimerKey = "ZMCallTimer"

extension NSManagedObjectContext {
    private var zm_callTimer: ZMCallTimer {
        if self.zm_isUserInterfaceContext {
            zmLog.warn("CallTimer should only be set on syncContext")
        }
        let oldTimer = self.userInfo[UserInfoCallTimerKey] as? ZMCallTimer
        return oldTimer ?? { () -> ZMCallTimer in
            let timer = ZMCallTimer(managedObjectContext: self)
            zmLog.debug("creating new timer")
            self.userInfo[UserInfoCallTimerKey] = timer
            return timer
            }()
    }

    public func zm_addAndStartCallTimer(conversation: ZMConversation) {
        if self.zm_isUserInterfaceContext {
            zmLog.warn("CallTimer should not be initiated on uiContext")
        }
        self.zm_callTimer.addAndStartTimer(conversation)
    }

    public func zm_resetCallTimer(conversation: ZMConversation) {
        if self.zm_isUserInterfaceContext {
            zmLog.warn("CallTimer can not be cancelled on uiContext")
        }
        self.zm_callTimer.resetTimer(conversation)
    }

    public func zm_tearDownCallTimer() {
        if let oldTimer = self.userInfo[UserInfoCallTimerKey] as? ZMCallTimer {
            oldTimer.tearDown()
        }
    }

    public func zm_hasTimerForConversation(conversation: ZMConversation) -> Bool {
        return self.zm_callTimer.conversationIDToTimerMap[conversation.objectID] != nil
    }
}

public protocol ZMCallTimerClient: NSObjectProtocol {

    func callTimerDidFire(timer: ZMCallTimer!)
}

public class ZMCallTimer: NSObject, ZMTimerClient {

    public var conversationIDToTimerMap: [NSManagedObjectID: ZMTimer] = [:]
    private weak var managedObjectContext: NSManagedObjectContext?

    public var testDelegate: ZMCallTimerClient?
    private var testTimeout: NSTimeInterval {
        return ZMVoiceChannelTimerTestTimeout
    }

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    public class func setTestCallTimeout(timeout: NSTimeInterval) {
        ZMVoiceChannelTimerTestTimeout = timeout
    }

    public class func resetTestCallTimeout() {
        ZMVoiceChannelTimerTestTimeout = 0
    }

    public func addAndStartTimer(conversation: ZMConversation) {
        let objectID = conversation.objectID
        if conversationIDToTimerMap[objectID] == nil && !conversation.callTimedOut {
            let timeOut = (testTimeout > 0) ? testTimeout : conversation.conversationType == .Group ? ZMVoiceChannelTimerTimeOutGroup : ZMVoiceChannelTimerTimeOutOneOnOne
            let timer = ZMTimer(target: self)
            timer.fireAtDate(NSDate().dateByAddingTimeInterval(timeOut))
            conversationIDToTimerMap[objectID] = timer
        }
    }

    public func resetTimer(conversation: ZMConversation) {
        cancelAndRemoveTimer(conversation.objectID)
    }

    private func cancelAndRemoveTimer(conversationID: NSManagedObjectID) {
        let timer = conversationIDToTimerMap[conversationID]
        if let timer = timer {
            timer.cancel()
        }
        conversationIDToTimerMap.removeValueForKey(conversationID)
    }

    public func timerDidFire(aTimer: ZMTimer) {
        for (conversationID, timer) in conversationIDToTimerMap {
            if timer != aTimer {
                return
            }
            self.cancelAndRemoveTimer(conversationID)
            if let testDelegate = self.testDelegate {
                testDelegate.callTimerDidFire(self)
            }
            guard let conversation = self.managedObjectContext?.objectWithID(conversationID) as? ZMManagedObject where !conversation.isZombieObject,
                let client = conversation as? ZMCallTimerClient else { return }
                client.callTimerDidFire(self)
            break
        }
    }

    public func tearDown() {
        for timer in Array(conversationIDToTimerMap.values) {
            timer.cancel()
        }
        conversationIDToTimerMap = [:]
    }

}
