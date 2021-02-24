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
import WireDataModel

extension Message {

    static var shortTimeFormatter: DateFormatter = {
        var shortTimeFormatter = DateFormatter()
        shortTimeFormatter.dateStyle = .none
        shortTimeFormatter.timeStyle = .short
        return shortTimeFormatter
    }()

    static let shortDateFormatter: DateFormatter = {
        var shortDateFormatter = DateFormatter()
        shortDateFormatter.dateStyle = .short
        shortDateFormatter.timeStyle = .none
        return shortDateFormatter
    }()

    static let spellOutDateTimeFormatter: DateFormatter = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .long
        longDateFormatter.timeStyle = .short
        longDateFormatter.doesRelativeDateFormatting = true
        return longDateFormatter
    }()

    static let shortDateTimeFormatter: DateFormatter = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .short
        longDateFormatter.timeStyle = .short
        return longDateFormatter
    }()

}
