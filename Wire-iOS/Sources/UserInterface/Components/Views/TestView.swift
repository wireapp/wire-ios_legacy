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
import Classy
import Cartography
import Foundation


extension UIView {
    // UI testing/debugging method.
    // Designed to show the instance of type @c self over the key window.
    // @param fullscreen should the view be stretched to fill the screen.
    @objc class func wr_testShowInstance(fullscreen: Bool = false) {
        guard DeveloperMenuState.developerMenuEnabled() else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            let newInstance = self.init()
            
            newInstance.wr_testShow(fullscreen: fullscreen)
        })
    }
    
    // UI testing/debugging method.
    // Designed to show the current instance over the key window.
    // @param fullscreen should the view be stretched to fill the screen.
    @objc func wr_testShow(fullscreen: Bool = false) {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return
        }
        
        keyWindow.addSubview(self)
        constrain(self, keyWindow) { selfView, keyWindow in
            selfView.left == keyWindow.left
            selfView.top == keyWindow.top
            if fullscreen {
                selfView.right == keyWindow.right
                selfView.bottom == keyWindow.bottom
            }
            else {
                selfView.right <= keyWindow.right
                selfView.bottom <= keyWindow.bottom
            }
        }
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.red.cgColor
        
        CASStyler.default().styleItem(self)
    }
}

open class TestView: UIView {
    let testLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(self.testLabel)
        
        self.testLabel.text = "push.notification.new_message".localized
        
        constrain(self, self.testLabel) { selfView, testLabel in
            testLabel.leading == selfView.leading + 24
            testLabel.trailing == selfView.trailing - 24
            testLabel.top == selfView.top
            testLabel.bottom == selfView.bottom
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
