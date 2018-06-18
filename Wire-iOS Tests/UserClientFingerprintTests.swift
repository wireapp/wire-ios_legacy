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


import XCTest
@testable import Wire

class UserClientFingerprintTests: XCTestCase {
    func testThatItMapsOctetCorrectly() {
        // given
        guard let data = Data(base64Encoded: "VUhVVQ==", options: []) else {
            XCTFail()
            return
        } // String "UHUU"
        
        // when
        let result = data.mapBytes(callback: { (char: UInt8) -> (String) in
            return String(UnicodeScalar(char))
        }).joined(separator: "")
        
        // then
        XCTAssertEqual(result, "UHUU")
    }
    
    func testThatItMapsWordCorrectly() {
        // given
        guard let data = Data(base64Encoded: "VUhVVQ==", options: []) else {
            XCTFail()
            return
        } // String "UHUU"
        
        // when
        let result = data.mapBytes(callback: { (char: UInt16) -> (String) in
            return String(UnicodeScalar(UInt8(truncatingIfNeeded: char))) + String(UnicodeScalar(UInt8(truncatingIfNeeded: char>>8)))
        }).joined(separator: "")
        
        // then
        XCTAssertEqual(result, "UHUU")
    }
    
    func testThatItMapsLongWordCorrectly() {
        // given
        let longStringAsText = "Maecenas euismod sollicitudin magna. Nullam pharetra ultricies eros, nec tincidunt nisi auctor id. Nullam pharetra ipsum eget gravida ornare. Curabitur finibus purus libero, at imperdiet massa volutpat ac. Aliquam erat volutpat. Integer at enim sit amet tellus euismod sollicitudin eget et ante. Vestibulum ut pretium turpis, in maximus arcu. Vivamus diam mauris, bibendum mollis est egestas, imperdiet viverra nunc. Quisque consequat purus et purus vehicula placerat. Aenean vitae quam ut lacus rhoncus euismod ac vel tellus. Fusce tellus sapien, pellentesque nec faucibus quis, sodales nec enim. Ut non turpis enim. Fusce fermentum leo nec urna faucibus luctus?."

        guard let data = Data(base64Encoded: "TWFlY2VuYXMgZXVpc21vZCBzb2xsaWNpdHVkaW4gbWFnbmEuIE51bGxhbSBwaGFyZXRyYSB1bHRyaWNpZXMgZXJvcywgbmVjIHRpbmNpZHVudCBuaXNpIGF1Y3RvciBpZC4gTnVsbGFtIHBoYXJldHJhIGlwc3VtIGVnZXQgZ3JhdmlkYSBvcm5hcmUuIEN1cmFiaXR1ciBmaW5pYnVzIHB1cnVzIGxpYmVybywgYXQgaW1wZXJkaWV0IG1hc3NhIHZvbHV0cGF0IGFjLiBBbGlxdWFtIGVyYXQgdm9sdXRwYXQuIEludGVnZXIgYXQgZW5pbSBzaXQgYW1ldCB0ZWxsdXMgZXVpc21vZCBzb2xsaWNpdHVkaW4gZWdldCBldCBhbnRlLiBWZXN0aWJ1bHVtIHV0IHByZXRpdW0gdHVycGlzLCBpbiBtYXhpbXVzIGFyY3UuIFZpdmFtdXMgZGlhbSBtYXVyaXMsIGJpYmVuZHVtIG1vbGxpcyBlc3QgZWdlc3RhcywgaW1wZXJkaWV0IHZpdmVycmEgbnVuYy4gUXVpc3F1ZSBjb25zZXF1YXQgcHVydXMgZXQgcHVydXMgdmVoaWN1bGEgcGxhY2VyYXQuIEFlbmVhbiB2aXRhZSBxdWFtIHV0IGxhY3VzIHJob25jdXMgZXVpc21vZCBhYyB2ZWwgdGVsbHVzLiBGdXNjZSB0ZWxsdXMgc2FwaWVuLCBwZWxsZW50ZXNxdWUgbmVjIGZhdWNpYnVzIHF1aXMsIHNvZGFsZXMgbmVjIGVuaW0uIFV0IG5vbiB0dXJwaXMgZW5pbS4gRnVzY2UgZmVybWVudHVtIGxlbyBuZWMgdXJuYSBmYXVjaWJ1cyBsdWN0dXM/Lg==", options: []) else {
            XCTFail()
            return
        } // Long String
        
        // when
        let result = data.mapBytes(callback: { (char: UInt16) -> (String) in
            let char1 = UInt8(truncatingIfNeeded: char)
            let char2 = UInt8(truncatingIfNeeded: char>>8)
            var result = ""
            
            if (char1 != 0) {
                result = result + String(UnicodeScalar(char1))
            }
            
            if (char2 != 0) {
                result = result + String(UnicodeScalar(char2))
            }
            
            return result
        }).joined(separator: "")
        
        // then
        XCTAssertEqual(result, longStringAsText)
    }
}
