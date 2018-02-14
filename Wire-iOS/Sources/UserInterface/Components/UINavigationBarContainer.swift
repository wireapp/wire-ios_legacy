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

    let landscapeTopMargin : CGFloat = 20.0
    let landscapeNavbarHeight : CGFloat = 30.0
    let portraitNavbarHeight : CGFloat = 44.0
    
    var navigationBar: UINavigationBar!
    var topMargin : NSLayoutConstraint?
    var navHeight : NSLayoutConstraint?
    
    init(_ navigationBar : UINavigationBar) {
        super.init(frame: .zero)
        self.navigationBar = navigationBar
        self.addSubview(navigationBar)
        self.backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBarBackground)
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func createConstraints() {
        constrain(navigationBar, self) { navigationBar, view in
            self.topMargin = navigationBar.top == view.top + UIScreen.safeArea.top
            self.navHeight = navigationBar.height == portraitNavbarHeight
            navigationBar.left == view.left
            navigationBar.right == view.right
            navigationBar.bottom == view.bottom
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let topMargin = topMargin, let navHeight = navHeight else { return }
        let orientation = UIApplication.shared.statusBarOrientation
        let deviceType = UIDevice.current.userInterfaceIdiom
        if(UIInterfaceOrientationIsLandscape(orientation) && deviceType == .phone) {
            topMargin.constant = landscapeTopMargin
            navHeight.constant = landscapeNavbarHeight
        } else {
            topMargin.constant = UIScreen.safeArea.top
            navHeight.constant = portraitNavbarHeight
        }
    }
}
