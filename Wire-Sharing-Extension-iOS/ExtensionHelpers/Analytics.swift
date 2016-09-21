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
import WireExtensionComponents

let ShareExtensionContext = "ShareExtension"

enum AnalyticsEvent: String {
    case Opened = "ShareExtensionOpened"
    case Closed = "ShareExtensionClosed"
}

enum AnalyticsEventAttribute {
    case numberOfImages(Int)
    case hasURL(Bool)
    case hasText(Bool)
    case numberOfRecipients(Int)
    case numberOfGroupRecipients(Int)
    case numberOfOneOnOneRecipients(Int)
    case cancel(String)

    func keyValue() -> (key: String, value: AnyObject) {
        var keyValue: (String, AnyObject) = ("", 0 as AnyObject)
        switch self {
        case .numberOfImages(let value): keyValue = ("numberOfImages", value as AnyObject)
        case .hasURL(let value): keyValue = ("hasURL", value as AnyObject)
        case .hasText(let value): keyValue = ("hasText", value as AnyObject)
        case .numberOfRecipients(let value): keyValue = ("numberOfRecipients", value as AnyObject)
        case .numberOfGroupRecipients(let value): keyValue = ("numberOfGroupRecipients", value as AnyObject)
        case .numberOfOneOnOneRecipients(let value): keyValue = ("numberOfOneOnOneRecipients", value as AnyObject)
        case .cancel(let value): keyValue = ("cancel", value as AnyObject)
        }
        return keyValue
    }
}

extension SharedAnalytics {
    
    func tagEvent(_ name: String) {
        self.tagEvent(name, attributes: nil)
    }
    
    func tagEvent(_ name: String, attributes: [AnyHashable: Any]?) {
        self.storeEvent(name, context: ShareExtensionContext, attributes: attributes)
    }
    
    func tagEvent(_ event: AnalyticsEvent, attributes: [AnalyticsEventAttribute]) {
        var attributeDict: [AnyHashable: Any] = [:]
        for attribute in attributes {
            let keyValue = attribute.keyValue()
            attributeDict[keyValue.key] = keyValue.value
        }
        
        self.tagEvent(event.rawValue, attributes: attributeDict)
    }
    
}
