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

public extension NSUUID {

    /// Returns whether this UUID is of Type 1
    @objc var isType1UUID : Bool {
        // looking at most significant bits of #7, as defined in: https://tools.ietf.org/html/rfc4122
        let type = ((self as UUID).uuid.6 & 0xf0) >> 4
        return type == 1
    }
    
    /// Read the given number of octets starting at the given location and reverts the octects order
    fileprivate func readOctectsReverted(_ start: UInt, len: UInt) -> UInt64 {
        let data = self.data()
        var result : UInt64 = 0
        for i in 0..<len {
            var readData : UInt8 = 0
            let finalOctetIndex = len-i-1
            let range = Range((Int(start+i))...(Int(start+i)))
            data?.copyBytes(to: &readData, from: range)
            let shiftedData = UInt64(readData) << UInt64(8*finalOctetIndex)
            result = result | shiftedData
        }
        return result
    }
    
    /// Returns the type 1 timestamp
    /// - returns: NSDate, or `nil` if the NSUUID is not of Type 1
    @objc var type1Timestamp : Date? {
        /*
        see https://tools.ietf.org/html/rfc4122
        UUID schema
        --------------------------------------------------------------------------------------------------------------------------
        .... | version / time_high 1 | time_high 2 | time_mid 1 | time_mid 2 | time_low 1 | time_low 2 | time_low 3 | time_low 4 |
        Octet:--7(4-7)-----7(0-3)-----------6------------5------------4------------3------------2------------1-------------0------
        */

        if !self.isType1UUID {
            return nil
        }
        
        // extracting fields
        let time_low = self.readOctectsReverted(0, len: 4)
        let time_mid = self.readOctectsReverted(4, len: 2)
        let time_high_and_variant = self.readOctectsReverted(4+2, len: 2)
        let time_high = (time_high_and_variant & 0x0fff)
        
        
        // calculting time
        let time : UInt64 = time_low |
            time_mid << 32 |
            time_high << 48
        let referenceDate : UInt64 = 0x01b21dd213814000 // 15 Oct 1582, 00:00:00
        let nanoseconds100SinceUnixTimestamp = time - referenceDate
        let nanoseconds100ToSeconds = Double(10000000)
        let unixTimestamp = Double(nanoseconds100SinceUnixTimestamp) / nanoseconds100ToSeconds
        return Date(timeIntervalSince1970: unixTimestamp)
    }

    /// Returns the comparison result for this NSUUID of type 1 and another NSUUID of type 1
    /// - Requires: will assert if any UUID is not of type 1
    @objc func compare(withType1UUID type1UUID: NSUUID) -> ComparisonResult {
        assert(self.isType1UUID && type1UUID.isType1UUID)
        return self.type1Timestamp!.compare(type1UUID.type1Timestamp!)
    }

    @objc static func timeBasedUUID() -> NSUUID {
        let uuidSize = MemoryLayout<uuid_t>.size
        let uuidPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: uuidSize)
        uuid_generate_time(uuidPointer)
        let uuid = NSUUID(uuidBytes: uuidPointer) as NSUUID
        uuidPointer.deallocate()
        return uuid
    }
}


public extension UUID {
    var isType1UUID : Bool {
        return (self as NSUUID).isType1UUID
    }
    
    fileprivate func readOctectsReverted(_ start: UInt, len: UInt) -> UInt64 {
        return (self as NSUUID).readOctectsReverted(start, len: len)
    }
    
    var type1Timestamp : Date? {
        return (self as NSUUID).type1Timestamp
    }
    
    func compare(withType1UUID type1UUID: NSUUID) -> ComparisonResult {
        return (self as NSUUID).compare(withType1UUID: type1UUID)
    }

    func compare(withType1 uuid: UUID) -> ComparisonResult {
        return (self as NSUUID).compare(withType1UUID: uuid as NSUUID)
    }
    
    static func timeBasedUUID() -> NSUUID {
        return NSUUID.timeBasedUUID()
    }
}
