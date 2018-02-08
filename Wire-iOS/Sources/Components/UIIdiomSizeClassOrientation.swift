//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

enum Orientation {
    case landscape, portrait, unknown
}

protocol UIIdiomSizeClassOrientationProtocol {
    
    var idiom: UIUserInterfaceIdiom {get}
    var horizontalSizeClass: UIUserInterfaceSizeClass?  {get}
    var orientation: Orientation?  {get}

    static func current() -> UIIdiomSizeClassOrientationProtocol
    func isIPadRegular() -> Bool 
}

extension UIIdiomSizeClassOrientationProtocol {
    func isIPadRegular() -> Bool {
        return self == UIIdiomSizeClassOrientation(idiom: .pad, horizontalSizeClass: .regular)
    }
}

func ==(lhs: UIIdiomSizeClassOrientationProtocol, rhs: UIIdiomSizeClassOrientationProtocol) -> Bool {

    // If one of the orientations is nil, return true
    var isOrientationEqual = false
    if let lhsOrientation = lhs.orientation, let rhsOrientation = rhs.orientation {
        isOrientationEqual = lhsOrientation == rhsOrientation
    }
    else {
        isOrientationEqual = true
    }

    return lhs.idiom == rhs.idiom && lhs.horizontalSizeClass == rhs.horizontalSizeClass && isOrientationEqual
}


/// Struct for replacing IS_IPAD_FULLSCREEN, IS_IPAD_PORTRAIT_LAYOUT and IS_IPAD_LANDSCAPE_LAYOUT objc macros.
struct UIIdiomSizeClassOrientation: UIIdiomSizeClassOrientationProtocol {
    var idiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    var horizontalSizeClass: UIUserInterfaceSizeClass?
    var orientation: Orientation?

    init() {
        horizontalSizeClass = UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass
        if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            orientation = .landscape
        }
        else if UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation) {
            orientation = .portrait
        }
        else {
            orientation = .unknown
        }
    }

    init(idiom: UIUserInterfaceIdiom, horizontalSizeClass: UIUserInterfaceSizeClass?, orientation: Orientation? = nil) {
        self.idiom = idiom
        self.horizontalSizeClass = horizontalSizeClass
        self.orientation = orientation
    }

    static func current() -> UIIdiomSizeClassOrientationProtocol {
        return UIIdiomSizeClassOrientation()
    }
}

extension UIIdiomSizeClassOrientation {

    /// Notice: these two methods used in UIViewController.viewWillTransition. It returns the original orientation, not the new orientation
    ///
    /// - Returns: true if current status is iPad in regular size class and orientation is landscape.
    static func isIPadRegularLandscape() -> Bool {
        let current = UIIdiomSizeClassOrientation.current()
        let iPadRegularLandscape: UIIdiomSizeClassOrientationProtocol = UIIdiomSizeClassOrientation(idiom: .pad, horizontalSizeClass: .regular, orientation: .landscape)

        return current == iPadRegularLandscape
    }

    static func isIPadRegularPortrait() -> Bool {
        return !UIIdiomSizeClassOrientation.isIPadRegularLandscape()
    }

    static func isPortrait() -> Bool {
        return UIIdiomSizeClassOrientation.current().orientation == .portrait
    }

    static func isLandscape() -> Bool {
        return UIIdiomSizeClassOrientation.current().orientation == .landscape
    }
}

