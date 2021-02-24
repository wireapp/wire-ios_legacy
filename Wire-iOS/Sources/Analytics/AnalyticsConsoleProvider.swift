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
import WireSystem
import WireDataModel

fileprivate let tag = "<ANALYTICS>:"
final class AnalyticsConsoleProvider: NSObject {

    let zmLog = ZMSLog(tag: tag)
    var optedOut = false

    required override init() {
        super.init()
        ZMSLog.set(level: .info, tag: tag)
    }

}

extension AnalyticsConsoleProvider: AnalyticsProvider {
    var isOptedOut: Bool {
        get {
            return optedOut
        }

        set {
            zmLog.info("Setting Opted out: \(newValue)")
            optedOut = newValue
        }
    }

    /// no-op
    var selfUser: UserType? {
        get {
            //no-op
            return nil
        }

        set {
            //no-op
        }
    }

    private func print(loggingData data: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted),
            let string = String(data: jsonData, encoding: .utf8) {
            zmLog.info(string)
        }
    }

    func tagEvent(_ event: String, attributes: [String: Any] = [:]) {

        let printableAttributes = attributes

        var loggingDict = [String: Any]()

        loggingDict["event"] = event

        if !printableAttributes.isEmpty {
            var localAttributes = [String: String]()
            printableAttributes.map({ (key, value) -> (String, String) in
                return (key, (value as AnyObject).description!)
            }).forEach({ (key, value) in
                localAttributes[key] = value
            })
            loggingDict["attributes"] = localAttributes
        }

        print(loggingData: loggingDict)
    }

    func setSuperProperty(_ name: String, value: Any?) {
        print(loggingData: ["superProperty_\(name)": value ?? "nil"])
    }

    func flush(completion: Completion?) {
        completion?()
    }
}

