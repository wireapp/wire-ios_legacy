//
//  PopUpIconButton.swift
//  Wire-iOS
//
//  Created by John Nguyen on 15.07.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit

public enum PopUpIconButtonExpandDirection {
    case left, right
}

public class PopUpIconButton: IconButton {

    public var itemIcons: [ZetaIconType] = []
    public var expandDirection: PopUpIconButtonExpandDirection = .right
    
    private var buttonView: PopUpIconButtonView?
    fileprivate let longPressGR = UILongPressGestureRecognizer()
    
    public func setupView() {
        longPressGR.addTarget(self, action: #selector(longPressHandler(gestureRecognizer:)))
        addGestureRecognizer(longPressGR)
    }
    
    @objc private func longPressHandler(gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            
            if buttonView == nil {
                buttonView = PopUpIconButtonView(withButton: self)
                window?.addSubview(buttonView!)
            }
            
        case .changed:
            let point = gestureRecognizer.location(in: window)
            buttonView!.updateSelectionForPoint(point)
            
        default:
            // update icon
            let icon = itemIcons[buttonView!.selectedIndex]
            setIcon(icon, with: .tiny, for: .normal)
            
            buttonView!.removeFromSuperview()
            buttonView = nil
        }
    }

}



