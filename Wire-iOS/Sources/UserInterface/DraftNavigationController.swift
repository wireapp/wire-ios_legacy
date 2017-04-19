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


final class DraftNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        navigationBar.isOpaque = true
        let textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        navigationBar.tintColor = textColor
        navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationBar.shadowImage = UIImage()
        let backImage = UIImage(for: .backArrow, iconSize: .tiny, color: ColorScheme.default().color(withName: ColorSchemeColorTextForeground))
        navigationBar.backIndicatorImage = backImage
        navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationBar.barTintColor = ColorScheme.default().color(withName: ColorSchemeColorBackgroundNew)
        navigationBar.titleTextAttributes = [
            NSFontAttributeName: FontSpec(.medium, .semibold).font!,
            NSForegroundColorAttributeName: textColor
        ]
    }

    override init(rootViewController: UIViewController) {
        let keyboardAvoiding = RotatingKeyboardAvoidingViewController(viewController: rootViewController)!
        super.init(rootViewController: keyboardAvoiding)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
