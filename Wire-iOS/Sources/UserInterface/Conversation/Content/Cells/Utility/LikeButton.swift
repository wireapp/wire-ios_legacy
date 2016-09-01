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

import Foundation
import Cartography

public class LikeButton: IconButton {
    public func setSelected(selected: Bool, animated: Bool) {
        if animated {
            guard let imageView = self.imageView else {
                return
            }
            
            let prevState: UIControlState
            if self.selected {
                prevState = .Selected
            }
            else {
                prevState = .Normal
            }

            let fakeImageView = UIImageView(image: UIImage.init(forIcon: self.iconTypeForState(prevState), iconSize: .Large, color: self.iconColorForState(prevState)))
            fakeImageView.frame = imageView.frame
            
            imageView.superview!.addSubview(fakeImageView)

            let image = UIImage.init(forIcon: self.iconTypeForState(.Selected), iconSize: .Large, color: self.iconColorForState(.Selected))
            let animationImageView = UIImageView(image: image)
            animationImageView.frame = imageView.frame
            imageView.superview!.addSubview(animationImageView)

            imageView.alpha = 0
            
            if selected { // gets like
                animationImageView.alpha = 0.0
                animationImageView.transform = CGAffineTransformMakeScale(6.3, 6.3)
                
                UIView.wr_animateWithEasing(RBBEasingFunctionEaseOutExpo, duration: 0.35, animations: {
                    animationImageView.transform = CGAffineTransformIdentity
                })
                
                UIView.wr_animateWithEasing(RBBEasingFunctionEaseOutQuart, duration: 0.35, animations: {
                        animationImageView.alpha = 1
                    }, completion: { _ in
                        animationImageView.removeFromSuperview()
                        fakeImageView.removeFromSuperview()
                        imageView.alpha = 1
                        self.selected = selected
                    })
            }
            else {
                
                UIView.wr_animateWithEasing(RBBEasingFunctionEaseInExpo, duration: 0.35, animations: {
                    animationImageView.transform = CGAffineTransformMakeScale(6.3, 6.3)
                })
                
                UIView.wr_animateWithEasing(RBBEasingFunctionEaseInQuart, duration: 0.35, animations: {
                    animationImageView.alpha = 0.0
                    }, completion: { _ in
                        animationImageView.removeFromSuperview()
                        fakeImageView.removeFromSuperview()
                        imageView.alpha = 1
                        self.selected = selected
                    })
            }
        }
        else {
            self.selected = selected
        }
    }
}
