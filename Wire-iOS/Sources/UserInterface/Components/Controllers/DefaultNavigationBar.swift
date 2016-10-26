//
//  DefaultNavigationBar.swift
//  Wire-iOS
//
//  Created by Jacob on 26/10/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit

class DefaultNavigationBar : UINavigationBar {

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
        tintColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        barTintColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        setBackgroundImage(UIImage.singlePixelImage(with: ColorScheme.default().color(withName: ColorSchemeColorBackground)), for: .default)
        titleTextAttributes = [NSFontAttributeName: UIFont(magicIdentifier: "style.text.title.font_spec"),
                               NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground)]
        setTitleVerticalPositionAdjustment(-2.0, for: .default)
        
        let separatorPixel = UIImage.singlePixelImage(with: ColorScheme.default().color(withName: ColorSchemeColorSeparator))
        let retinaSeparatorPixel = UIImage(cgImage: separatorPixel!.cgImage!, scale: 2, orientation: separatorPixel!.imageOrientation)
        shadowImage = retinaSeparatorPixel
        
    }
    
}

extension UIViewController {
    
    func wrap(inNavigationControllerClass navigationControllerClass: UINavigationController.Type) -> UINavigationController {
        let navigationController = navigationControllerClass.init(navigationBarClass: DefaultNavigationBar.self, toolbarClass: nil)
        navigationController.setViewControllers([self], animated: false)
        return navigationController
    }
    
}
