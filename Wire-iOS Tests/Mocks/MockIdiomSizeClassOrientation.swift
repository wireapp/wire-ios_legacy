//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
@testable import Wire

struct MockIdiomSizeClassOrientation: UIIdiomSizeClassOrientationProtocol {
    var idiom: UIUserInterfaceIdiom
    var horizontalSizeClass: UIUserInterfaceSizeClass?
    var orientation: Orientation?
    
    static var currentIdiom = UIUserInterfaceIdiom.unspecified
    static var currentHorizontalSizeClass = UIUserInterfaceSizeClass.unspecified
    static var currentOrientation = Orientation.unknown
    
    static func current() -> UIIdiomSizeClassOrientationProtocol {
        return MockIdiomSizeClassOrientation(idiom: currentIdiom, horizontalSizeClass: currentHorizontalSizeClass, orientation: currentOrientation)
    }
}
