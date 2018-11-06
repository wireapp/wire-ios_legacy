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

import UIKit

@objcMembers class DefaultNavigationBar : UINavigationBar {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configure()
    }
    
    func configure() {
        isTranslucent = false
        tintColor = UIColor.from(scheme: .textForeground)
        barTintColor = UIColor.from(scheme: .barBackground)
        setBackgroundImage(UIImage.singlePixelImage(with: UIColor.from(scheme: .barBackground)), for: .default)
        shadowImage = UIImage.singlePixelImage(with: UIColor.clear)
        titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: ColorScheme.default.variant)
        
        let backIndicatorInsets = UIEdgeInsets(top: 0, left: 4, bottom: 2.5, right: 0)
        backIndicatorImage = UIImage(for: .backArrow, iconSize: .tiny, color: UIColor.from(scheme: .textForeground)).withInsets(backIndicatorInsets, backgroundColor: .clear)
        backIndicatorTransitionMaskImage = UIImage(for: .backArrow, iconSize: .tiny, color: .black).withInsets(backIndicatorInsets, backgroundColor: .clear)
    }
    
    static func titleTextAttributes(for variant: ColorSchemeVariant) -> [NSAttributedString.Key : Any] {
        return [.font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold),
                .foregroundColor: UIColor.from(scheme: .textForeground, variant: variant),
                .baselineOffset: 1.0]
    }
    
}

extension UIViewController {
    
    @objc func wrapInNavigationController() -> UINavigationController {
        return self.wrapInNavigationController(RotationAwareNavigationController.self)
    }
    
    @objc func wrapInNavigationController(_ navigationControllerClass: UINavigationController.Type) -> UINavigationController {
        let navigationController = navigationControllerClass.init(navigationBarClass: DefaultNavigationBar.self, toolbarClass: nil)
        navigationController.setViewControllers([self], animated: false)
        return navigationController
    }
    
}
