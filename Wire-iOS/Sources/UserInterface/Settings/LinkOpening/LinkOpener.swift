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


private let log = ZMSLog(tag: "link opening")


public extension NSURL {

    @discardableResult @objc func open() -> Bool {
        return (self as URL).open()
    }

}

public extension URL {

    @discardableResult func open() -> Bool {
        let opened = openAsTweet() || openAsLink()
        if opened {
            return true
        }
        else {
            log.debug("Did not open \"\(self)\" in a twitter application or third party browser.")
            if UIApplication.shared.canOpenURL(self) {
                UIApplication.shared.openURL(self)
                return true
            }
            else {
                return false
            }
        }
    }
}

protocol LinkOpeningOption {

    static var allOptions: [Self] { get }
    var isAvailable: Bool { get }
    var displayString: String { get }
    static var availableOptions: [Self] { get }

}


extension LinkOpeningOption {

    static var availableOptions: [Self] {
        return allOptions.filter { $0.isAvailable }
    }

    static var optionsAvailable: Bool {
        return availableOptions.count > 1
    }

}


extension UIApplication {

    func canHandleScheme(_ scheme: String) -> Bool {
        return URL(string: scheme).map(canOpenURL) ?? false
    }

}
