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

extension StaticString {
    func utf8SignedStart() -> UnsafePointer<Int8> {
        let fileUnsafePointer = self.utf8Start
        let reboundToSigned = fileUnsafePointer.withMemoryRebound(to: Int8.self, capacity: self.utf8CodeUnitCount) {
            return UnsafePointer($0)
        }
        return reboundToSigned
    }
}

extension ZMSnapshotTestCase {
    func verify(view: UIView, tolerance: Float = 0, file: StaticString = #file, line: UInt = #line) {
        verifyView(view, tolerance: tolerance, file: file.utf8SignedStart(), line: line)
    }
    
    func verifyInAllPhoneWidths(view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllPhoneWidths: view, file: file.utf8SignedStart(), line: line)
    }
    
    func verifyInAllTabletWidths(view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllTabletWidths: view, file: file.utf8SignedStart(), line: line)
    }
    
    func verifyInAllIPhoneSizes(view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllPhoneSizes: view, file: file.utf8SignedStart(), line: line, configurationBlock: nil)
    }
}
