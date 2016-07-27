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

extension ZMSnapshotTestCase {
    func verify(view view: UIView, tolerance: Float = 0, file: StaticString = #file, line: UInt = #line) {
        verifyView(view, tolerance: tolerance, file: UnsafePointer<Int8>(file.utf8Start), line: line)
    }
    
    func verifyInAllPhoneWidths(view view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyViewInAllPhoneWidths(view, file: UnsafePointer<Int8>(file.utf8Start), line: line)
    }
    
    func verifyInAllTabletWidths(view view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyViewInAllTabletWidths(view, file: UnsafePointer<Int8>(file.utf8Start), line: line)
    }
}
