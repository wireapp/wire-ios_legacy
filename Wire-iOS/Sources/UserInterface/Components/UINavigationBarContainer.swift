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

import UIKit
import Cartography

class UINavigationBarContainer: UIView {

    var navigationBar: UINavigationBar!
    var topMargin : NSLayoutConstraint?
    
    init(_ navigationBar : UINavigationBar) {
        super.init(frame: .zero)
        self.navigationBar = navigationBar
        self.addSubview(navigationBar)
        self.backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func createConstraints() {
        constrain(navigationBar, self) { (navigationBar: LayoutProxy, view: LayoutProxy) -> () in
            self.topMargin = navigationBar.top == view.top + UIScreen.safeArea.top
            navigationBar.height == 44.0
            navigationBar.left == view.left
            navigationBar.right == view.right
            navigationBar.bottom == view.bottom
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let topMargin = topMargin else { return }
        let orientation = UIDevice.current.orientation
        let deviceType = UIDevice.current.userInterfaceIdiom
        if(UIDeviceOrientationIsLandscape(orientation) && deviceType == .phone) {
            topMargin.constant = 0.0
        } else {
            topMargin.constant = UIScreen.safeArea.top
        }
    }
}
