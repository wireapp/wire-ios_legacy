
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension FullscreenImageViewController {
    // MARK: - Utilities, custom UI
    func performSaveImageAnimation(from saveView: UIView) {
        guard let imageView = imageView else { return }
        
        let ghostImageView = UIImageView(image: imageView.image)
        ghostImageView.contentMode = .scaleAspectFit
        ghostImageView.translatesAutoresizingMaskIntoConstraints = false

        ghostImageView.frame = view.convert(imageView.frame, from: imageView.superview)
        view.addSubview(ghostImageView)

        let targetCenter = view.convert(saveView.center, from: saveView.superview)
        
        UIView.animate(easing: .easeInExpo, duration: 0.55, animations: {
            ghostImageView.center = targetCenter
            ghostImageView.alpha = 0
            ghostImageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }) { _ in
            ghostImageView.removeFromSuperview()
        }
    }
}
