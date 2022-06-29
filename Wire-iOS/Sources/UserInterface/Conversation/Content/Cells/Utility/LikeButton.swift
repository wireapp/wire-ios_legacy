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
import UIKit

final class LikeButton: IconButton {
    static var normalColor: UIColor {
        return UIColor.from(scheme: .textDimmed)
    }

    static var selectedColor: UIColor {
        return UIColor(for: .red)
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        // Do not animate changes if the state does not change
        guard selected != self.isSelected else {
            return
        }

        if animated {
            guard let imageView = self.imageView else {
                return
            }

            let prevState: UIControl.State
            if self.isSelected {
                prevState = .selected
            } else {
                prevState = []
            }

            let currentIcon = icon(for: prevState) ?? (prevState == .selected ? .liked : .like)
            let fakeImageView = UIImageView()
            fakeImageView.setIcon(currentIcon, size: .large, color: self.iconColor(for: prevState) ?? LikeButton.normalColor)
            fakeImageView.frame = imageView.frame

            imageView.superview!.addSubview(fakeImageView)

            let selectedIcon = icon(for: prevState) ?? .liked
            let animationImageView = UIImageView()
            animationImageView.setIcon(selectedIcon, size: .large, color: LikeButton.selectedColor)
            animationImageView.frame = imageView.frame
            imageView.superview!.addSubview(animationImageView)

            imageView.alpha = 0
            if selected { // gets like
                animationImageView.alpha = 0.0
                animationImageView.transform = CGAffineTransform(scaleX: 6.3, y: 6.3)

                UIView.animate(easing: .easeOutExpo, duration: 0.35, animations: {
                    animationImageView.transform = CGAffineTransform.identity
                })

                UIView.animate(easing: .easeOutQuart, duration: 0.35, animations: {
                        animationImageView.alpha = 1
                    }, completion: { _ in
                        animationImageView.removeFromSuperview()
                        fakeImageView.removeFromSuperview()
                        imageView.alpha = 1
                        self.isSelected = selected
                    })
            } else {

                UIView.animate(easing: .easeInExpo, duration: 0.35, animations: {
                    animationImageView.transform = CGAffineTransform(scaleX: 6.3, y: 6.3)
                })

                UIView.animate(easing: .easeInQuart, duration: 0.35, animations: {
                    animationImageView.alpha = 0.0
                    }, completion: { _ in
                        animationImageView.removeFromSuperview()
                        fakeImageView.removeFromSuperview()
                        imageView.alpha = 1
                        self.isSelected = selected
                    })
            }

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            self.isSelected = selected
        }
    }
}
