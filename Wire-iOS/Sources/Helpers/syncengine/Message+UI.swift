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

private let zmLog = ZMSLog(tag: "Message+UI")

extension Message {
    class func formattedReceivedDate(for message: ZMConversationMessage) -> String {///TODO: property of message
        
        let serverTimestamp: Date
            
        if let messageServerTimestamp = message.serverTimestamp {
            serverTimestamp = messageServerTimestamp
        } else {
            // Today's date
            serverTimestamp = Date()
        }
        
        return serverTimestamp.formattedDate
    }
    
    class func shouldShowTimestamp(_ message: ZMConversationMessage) -> Bool {
        let allowedType = Message.isText(message) ||
            Message.isImage(message) ||
            Message.isFileTransfer(message) ||
            Message.isKnock(message) ||
            Message.isLocation(message) ||
            Message.isDeleted(message) ||
            Message.isMissedCall(message) ||
            Message.isPerformedCall(message)
        
        return allowedType
    }
    
    class func shouldShowDeliveryState(_ message: ZMConversationMessage) -> Bool {
        return !Message.isPerformedCall(message) &&
               !Message.isMissedCall(message)
    }
    
    ///TODO: this ls lazy?
    static var shortTimeFormatter: DateFormatter = {
        var shortTimeFormatter = DateFormatter()
        shortTimeFormatter.dateStyle = .none
        shortTimeFormatter.timeStyle = .short
        return shortTimeFormatter
    }()
    
//    class func shortTimeFormatter() -> DateFormatter? {
//        // `dispatch_once()` call was converted to a static variable initializer
//
//        return shortTimeFormatter
//    }
    
    ///TODO: this is lazy?
    static let shortDateFormatter : DateFormatter = {
        var shortDateFormatter = DateFormatter()
        shortDateFormatter.dateStyle = .short
        shortDateFormatter.timeStyle = .none
        return shortDateFormatter
    }()
    
//    class var shortDateFormatter: DateFormatter {
//        // `dispatch_once()` call was converted to a static variable initializer
//
//        return shortDateFormatter
//    }
    
    static let shortDateTimeLongDateFormatter: DateFormatter = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .long
        longDateFormatter.timeStyle = .short
        longDateFormatter.doesRelativeDateFormatting = true
        return longDateFormatter
    }()
    
    class var shortDateTimeFormatter: DateFormatter {
        return shortDateTimeLongDateFormatter
    }
    
    ///TODO: lazy?
    static let spellOutDateTimeFormatter: DateFormatter = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .short
        longDateFormatter.timeStyle = .short
        return longDateFormatter
    }()
    
//    class var spellOutDateTimeFormatter: DateFormatter {
//        // `dispatch_once()` call was converted to a static variable initializer
//
//        return spellOutDateTimeLongDateFormatter
//    }

    class func nonNilImageDataIdentifier(_ message: ZMConversationMessage) -> String? {
        if let identifier = message.imageMessageData?.imageDataIdentifier {
            return identifier
        }
        
        zmLog.warn("Image cache key is nil!")
        if let imageData = message.imageMessageData?.imageData { ///TODO: check/test
//            return [NSString stringWithFormat:@"nonnil-%p", message.imageMessageData.imageData];
            return "nonnil-\(imageData.hashValue)"
        }
        return nil
    }
    
    class func canBePrefetched(_ message: ZMConversationMessage) -> Bool {
        return Message.isImage(message) ||
               Message.isFileTransfer(message) ||
               Message.isText(message)
    }

}
