//
//  UIView+ContentInsets.swift
//  Wire-iOS
//
//  Created by Jacob Persson on 08.03.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation

extension UIView {
    
    @objc class var conversationLayoutMargins: UIEdgeInsets {
        var left: CGFloat = CGFloat.nan
        var right: CGFloat = CGFloat.nan
        
        // keyWindow can be nil, in case when running tests or the view is not added to view hierachy
        switch (UIApplication.shared.keyWindow?.traitCollection.horizontalSizeClass) {
        case (.compact?):
            left = 56
            right = 16
        case (.regular?):
            left = 96
            right = 96
        default:
            left = 56
            right = 16
        }
        
        return UIEdgeInsets(top: 0, left: left, bottom: 0, right: right)
    }
    
    @objc class var directionAwareConversationLayoutMargins: UIEdgeInsets {
        let margins = conversationLayoutMargins
        
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return UIEdgeInsets(top: margins.top, left: margins.right, bottom: margins.bottom, right: margins.left)
        } else {
            return margins
        }
    }
    
}
