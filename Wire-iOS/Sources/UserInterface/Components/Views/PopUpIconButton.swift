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

public enum PopUpIconButtonExpandDirection {
    case left, right
}

protocol PopUpIconButtonDelegate: class {
    func popUpIconButton(_ button: PopUpIconButton, didSelectIcon icon: ZetaIconType)
}

public class PopUpIconButton: IconButton {

    weak var delegate: PopUpIconButtonDelegate?
    public var itemIcons: [ZetaIconType] = []
    
    private var buttonView: PopUpIconButtonView?
    fileprivate let longPressGR = UILongPressGestureRecognizer()
    
    public func setupView() {
        longPressGR.minimumPressDuration = 0.15
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
            
            delegate?.popUpIconButton(self, didSelectIcon: icon)
        }
    }

}



