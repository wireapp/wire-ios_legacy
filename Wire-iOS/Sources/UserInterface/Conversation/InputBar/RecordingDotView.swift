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

@objcMembers final class RecordingDotView: UIView {
    
    public init() {
        super.init(frame: CGRect.zero)
        
        backgroundColor = .vividRed
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.width / 2
    }
    
    public var animating: Bool = false {
        didSet {
            if oldValue == animating {
                return
            }
            
            if animating {
                self.startAnimation()
            }
            else {
                self.stopAnimation()
            }
        }
    }
    
    fileprivate func startAnimation() {
        self.alpha = 0
        delay(0.15) { 
            UIView.animate(withDuration: 0.55, delay: 0, options: [.autoreverse, .repeat], animations: {
                self.alpha = 1
                }, completion: .none)
        }
    }
    
    fileprivate func stopAnimation() {
        self.layer.removeAllAnimations()
        self.alpha = 1
    }
}
