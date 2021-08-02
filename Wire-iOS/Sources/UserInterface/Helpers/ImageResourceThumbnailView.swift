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
import UIKit
import WireCommonComponents

final class ImageResourceThumbnailView: RoundedView {

    private let imageView = ImageContentView()
    private let coverView = UIView()
    private let assetTypeBadge = UIImageView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        addSubview(imageView)

        coverView.backgroundColor = UIColor(white: 0, alpha: 0.24)
        addSubview(coverView)

        coverView.addSubview(assetTypeBadge)
    }

    private func configureConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        coverView.translatesAutoresizingMaskIntoConstraints = false
        assetTypeBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // imageView
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // coverView
            coverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            coverView.topAnchor.constraint(equalTo: imageView.topAnchor),
            coverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            coverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            // assetTypeBadge
            assetTypeBadge.widthAnchor.constraint(equalToConstant: 16),
            assetTypeBadge.heightAnchor.constraint(equalToConstant: 16),
            assetTypeBadge.topAnchor.constraint(greaterThanOrEqualTo: coverView.topAnchor, constant: 6),
            assetTypeBadge.leadingAnchor.constraint(equalTo: coverView.leadingAnchor, constant: 8),
            assetTypeBadge.bottomAnchor.constraint(equalTo: coverView.bottomAnchor, constant: -6)
        ])
    }

    // MARK: - Content

    override var intrinsicContentSize: CGSize {
        return imageView.intrinsicContentSize
    }

    func setResource(_ resource: PreviewableImageResource, isVideoPreview: Bool) {
        imageView.configure(with: resource) {
            DispatchQueue.main.async {
                let needsVideoCoverView = isVideoPreview && self.imageView.mediaAsset != nil
                self.coverView.isHidden = !needsVideoCoverView
                self.assetTypeBadge.image = needsVideoCoverView ? StyleKitIcon.videoCall.makeImage(size: .tiny, color: .white) : nil
            }
        }
    }

}
