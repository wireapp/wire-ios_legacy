//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ImageContentView: UIView {
    
    var imageView = ImageResourceView()
    var imageAspectConstraint: NSLayoutConstraint?
    var imageWidthConstraint: NSLayoutConstraint
    var imageHeightConstraint: NSLayoutConstraint

    var mediaAsset: MediaAsset? {
        return imageView.mediaAsset()
    }

    init() {
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 140)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 140)
        
        super.init(frame: .zero)
        
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageWidthConstraint.priority = .defaultLow
        imageHeightConstraint.priority = .defaultLow
        
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint,
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with resource: PreviewableImageResource, completionHandler: (() -> Void)? = nil) {
        updateAspectRatio(for: resource)
        imageView.setImageResource(resource, completion: completionHandler)
    }

    private func updateAspectRatio(for resource: PreviewableImageResource) {
        let contentSize = resource.contentSize
        imageAspectConstraint.apply(imageView.removeConstraint)
        imageAspectConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: contentSize.height / contentSize.width)
        imageAspectConstraint?.isActive = true
        imageWidthConstraint.constant = contentSize.width
        imageHeightConstraint.constant = contentSize.height
        imageView.contentMode = resource.contentMode
    }

}
