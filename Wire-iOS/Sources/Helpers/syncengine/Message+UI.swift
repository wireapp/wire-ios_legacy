//
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

extension Message {
    class func formattedReceivedDate(for message: ZMConversationMessage) -> String {///TODO: property of message
        // Today's date
        let today = Date()
        
        var serverTimestamp = message.serverTimestamp
        if serverTimestamp == nil {
            serverTimestamp = today
        }
        
        return serverTimestamp.formattedString
    }
    
    class func shouldShowTimestamp(_ message: ZMConversationMessage?) -> Bool {
        let allowedType = Message.isTextMessage(message) || Message.isImageMessage(message) || Message.isFileTransferMessage(message) || Message.isKnock(message) || Message.isLocationMessage(message) || Message.isDeletedMessage(message) || Message.isMissedCall(message) || Message.isPerformedCall(message)
        
        return allowedType
    }
    
    class func shouldShowDeliveryState(_ message: ZMConversationMessage?) -> Bool {
        return !Message.isPerformedCall(message) && !Message.isMissedCall(message)
    }
    
    static var shortTimeFormatter: DateFormatter = {
        var shortTimeFormatter = DateFormatter()
        shortTimeFormatter?.dateStyle = .none
        shortTimeFormatter?.timeStyle = .short
        return shortTimeFormatter
    }()
    
    class func shortTimeFormatter() -> DateFormatter? {
        // `dispatch_once()` call was converted to a static variable initializer
        
        return shortTimeFormatter
    }
    
    static var shortDateFormatter = {
        var shortDateFormatter = DateFormatter()
        shortDateFormatter?.dateStyle = .short
        shortDateFormatter?.timeStyle = .none
        return shortDateFormatter
    }()
    
    class func shortDateFormatter() -> DateFormatter? {
        // `dispatch_once()` call was converted to a static variable initializer
        
        return shortDateFormatter
    }
    
    static let shortDateTimeLongDateFormatter: DateFormatter? = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .long
        longDateFormatter.timeStyle = .short
        longDateFormatter.doesRelativeDateFormatting = true
        return longDateFormatter
    }()
    
    class func shortDateTimeFormatter() -> DateFormatter? {
        // `dispatch_once()` call was converted to a static variable initializer
        
        return shortDateTimeLongDateFormatter
    }
    
    static let spellOutDateTimeLongDateFormatter: DateFormatter? = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .short
        longDateFormatter.timeStyle = .short
        return longDateFormatter
    }()
    
    class func spellOutDateTimeFormatter() -> DateFormatter? {
        // `dispatch_once()` call was converted to a static variable initializer
        
        return spellOutDateTimeLongDateFormatter
    }

    class func nonNilImageDataIdentifier(_ message: ZMConversationMessage?) -> String? {
        let identifier = message?.imageMessageData.imageDataIdentifier
        if identifier == nil {
            ZMLogWarn("Image cache key is nil!")
            if let imageData = message?.imageMessageData.imageData {
                return String(format: "nonnil-%p", imageData)
            }
            return nil
        }
        return identifier
    }
    
    class func canBePrefetched(_ message: ZMConversationMessage?) -> Bool {
        return Message.isImageMessage(message) || Message.isFileTransferMessage(message) || Message.isTextMessage(message)
    }

}
