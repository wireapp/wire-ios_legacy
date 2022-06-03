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

public extension UUID {
    
    /// return a Data representation of this UUID
    var uuidData: Data {
        return withUnsafeBytes(of: uuid, Data.init(_:))
    }
    
    
    /// Create an UUID from Data. Fails when Data is not in valid format
    ///
    /// - Parameter data: a data with count = 16.
    init?(data: Data) {
        guard data.count == 16 else { return nil }
        
        self.init(uuid: (data[0],
                         data[1],
                         data[2],
                         data[3],
                         data[4],
                         data[5],
                         data[6],
                         data[7],
                         data[8],
                         data[9],
                         data[10],
                         data[11],
                         data[12],
                         data[13],
                         data[14],
                         data[15]))
    }
}
