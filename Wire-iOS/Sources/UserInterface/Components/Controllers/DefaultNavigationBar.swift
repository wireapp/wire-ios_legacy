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
import WireCommonComponents

final class LightNavigationBar: DefaultNavigationBar {
    override var colorSchemeVariant: ColorSchemeVariant {
        return .light
    }
}

class DefaultNavigationBar: UINavigationBar {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    var colorSchemeVariant: ColorSchemeVariant {
        return ColorScheme.default.variant
    }
    
    func configure() {
        tintColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: colorSchemeVariant)
        configureBackground()

        let backIndicatorInsets = UIEdgeInsets(top: 0, left: 4, bottom: 2.5, right: 0)
        backIndicatorImage = StyleKitIcon.backArrow.makeImage(size: .tiny, color: UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)).with(insets: backIndicatorInsets, backgroundColor: .clear)
        backIndicatorTransitionMaskImage = StyleKitIcon.backArrow.makeImage(size: .tiny, color: .black).with(insets: backIndicatorInsets, backgroundColor: .clear)
    }

    func configureBackground() {
        isTranslucent = false
        barTintColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
        setBackgroundImage(UIImage.singlePixelImage(with: UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)), for: .default)
        shadowImage = UIImage.singlePixelImage(with: UIColor.clear)
    }
    
    static func titleTextAttributes(for variant: ColorSchemeVariant) -> [NSAttributedString.Key: Any] {
        return [.font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold),
                .foregroundColor: UIColor.from(scheme: .textForeground, variant: variant),
                .baselineOffset: 1.0]
    }
    
}

extension UIViewController {

    func wrapInNavigationController(navigationControllerClass: UINavigationController.Type = RotationAwareNavigationController.self,
                                    navigationBarClass: AnyClass? = DefaultNavigationBar.self) -> UINavigationController {
        let navigationController = navigationControllerClass.init(navigationBarClass: navigationBarClass, toolbarClass: nil)
        navigationController.setViewControllers([self], animated: false)
        return navigationController
    }

    // MARK: - present
    func wrapInNavigationControllerAndPresent(from viewController: UIViewController) -> UINavigationController {
        let navigationController = wrapInNavigationController()
        navigationController.modalPresentationStyle = .formSheet
        viewController.present(navigationController, animated: true)

        return navigationController
    }

}
