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
import ZMCSystem

fileprivate let tag = "<ANALYTICS>:"
@objc class AnalyticsConsoleProvider : NSObject {
    
    let zmLog = ZMSLog(tag: tag)
    var optedOut = false

    public required init!(launchOptions: [AnyHashable : Any]! = [:]) {
        super.init()
        ZMSLog.set(level: .info, tag: tag)
    }

}

extension AnalyticsConsoleProvider: AnalyticsProvider {

    public var isOptedOut : Bool {
        get {
            return optedOut
        }
        
        set {
            zmLog.info("Setting Opted out: \(newValue)")
            optedOut = newValue
        }
    }
    
    private func print(loggingData data: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted),
            let string = String(data: jsonData, encoding: .utf8) {
            zmLog.info(string)
        }
    }
    
    func tagScreen(_ screen: String!) {
        if screen != nil {
            print(loggingData:["screen" : screen])
        }
    }
    
    func tagEvent(_ event: String!) {
        tagEvent(event, attributes: [:])
    }
    
    func tagEvent(_ event: String!, attributes: [AnyHashable : Any]! = [:]) {
        tagEvent(event, attributes: attributes, customerValueIncrease: nil)
    }
    
    func tagEvent(_ event: String!, attributes: [AnyHashable : Any]! = [:], customerValueIncrease: NSNumber!) {
        var printableAttributes = [AnyHashable : Any]()
        
        if attributes != nil {
            printableAttributes = attributes
        }
        
        var loggingDict = [String : Any]()
        
        if event != nil {
            loggingDict["event"] = event
        }
        
        if !printableAttributes.isEmpty {
            var localAttributes = [String : String]()
            printableAttributes.map({ (key, value) -> (String, String) in
                return (key as! String, (value as AnyObject).description!)
            }).forEach({ (key, value) in
                localAttributes[key] = value
            })
            loggingDict["attributes"] = localAttributes
        }
        
        if customerValueIncrease != nil {
            loggingDict["customerValueIncrease"] = customerValueIncrease.description
        }
        print(loggingData: loggingDict)
    }
    
    func setCustomDimension(_ dimension: Int32, value: String!) {
        print(loggingData: ["customeDimension_\(dimension)" : value])
    }

}

