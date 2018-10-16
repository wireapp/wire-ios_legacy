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

extension UIViewController {

    @objc var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11, *) {
            return self.view.safeAreaLayoutGuide.bottomAnchor
        }
        else {
            return self.bottomLayoutGuide.topAnchor
        }
    }
    
    @objc var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11, *) {
            return self.view.safeAreaLayoutGuide.topAnchor
        }
        else {
            return self.topLayoutGuide.bottomAnchor
        }
    }

}

extension UIView {

    @objc var safeAreaLayoutGuideOrFallback: UILayoutGuide {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }

    @objc var safeAreaInsetsOrFallback: UIEdgeInsets {
        if #available(iOS 11, *) {
            return safeAreaInsets
        } else {
            return .zero
        }
    }

    @objc var safeLeadingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.leadingAnchor
        } else {
            return leadingAnchor
        }
    }

    @objc var safeTrailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.trailingAnchor
        } else {
            return trailingAnchor
        }
    }

    @objc var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.bottomAnchor
        }
        else {
            return bottomAnchor
        }
    }

    @objc var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.topAnchor
        }
        else {
            return topAnchor
        }
    }

    @objc var safeCenterYAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.centerYAnchor
        }
        else {
            return centerYAnchor
        }
    }

    @objc var safeCenterXAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.centerXAnchor
        }
        else {
            return centerXAnchor
        }
    }


}
