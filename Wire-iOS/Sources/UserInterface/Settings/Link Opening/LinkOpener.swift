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


public extension NSURL {

    @objc func open() {
        (self as URL).open()
    }

}

public extension URL {

    func open() {
        let openened = openAsTweet() || openAsLink()
        if !openened {
            UIApplication.shared.openURL(self)
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
