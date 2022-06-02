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

import WireUtilities

extension Data: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        return "<\(self.readableHash)>"
    }
}

// This allows for dump of data in safe logs. It's called "unsafe" because the data is
// dumped as-is, no hashing is applied. Be aware of what you are dumping here.
struct HexDumpUnsafeLoggingData: SafeForLoggingStringConvertible {
    
    let data: Data
    
    public var safeForLoggingDescription: String {
        return data.zmHexEncodedString()
    }
}
