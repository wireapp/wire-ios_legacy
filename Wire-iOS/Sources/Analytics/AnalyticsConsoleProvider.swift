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
    
    override init() {
        super.init()
        ZMSLog.set(level: .info, tag: tag)
    }
}

extension AnalyticsConsoleProvider : AnalyticsProvider {

    public var isOptedOut : Bool {
        
        get {
            return optedOut
        }
        
        set {
            zmLog.info("Setting Opted out: \(newValue)")
            optedOut = newValue
        }
    }
    
    func tagScreen(_ screen: String!) {
        zmLog.info("Tagging Screen: \(screen ?? "")")
    }
    
    func tagEvent(_ event: String!) {
        tagEvent(event, attributes: [:])
    }
    
    func tagEvent(_ event: String!, attributes: [AnyHashable : Any]! = [:]) {
        tagEvent(event, attributes: attributes, customerValueIncrease: nil)
    }
    
    func tagEvent(_ event: String!, attributes: [AnyHashable : Any]! = [:], customerValueIncrease: NSNumber!) {
        var string = "Tagging Event: \(event ?? "")"
        if !attributes.isEmpty {
            let keyValues = attributes.map({ (key, value) -> (String, Any) in
                return (key as! String, value)
            })
            string.append("\n Attributes: \(keyValues)")
        }
        
        if customerValueIncrease != nil {
            string.append("\n Customer Value Increase: \(customerValueIncrease)")
        }
        zmLog.info(string)
    }
    
    func setCustomerID(_ customerID: String!) {
        zmLog.info("Setting Customer ID: \(customerID ?? "" )")
    }
    
    func setPushToken(_ token: Data!) {
        zmLog.info("Setting push token: \(token ?? Data() )")
    }
    
    func setCustomDimension(_ dimension: Int32, value: String!) {
        zmLog.info("Setting Custom Dimension: \(dimension) Value: \(value ?? "" )")
    }
    
    func upload() {
        zmLog.info("Uploading")
    }
    
    func resume(handler resumeHandler: ResumeHandlerBlock!) {
        //no-op
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable : Any]!) {
        //no-op
    }
    
    func handleOpen(_ url: URL!) -> Bool {
        zmLog.info("Opening URL: \(url)")
        return false
    }
    
    func close() {
        zmLog.info("Closing")
    }
}

