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
import UIKit
import WireDataModel

final class CollectionLoadingCell: UICollectionViewCell {
    let loadingView = UIActivityIndicatorView(style: .gray)

    public override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(loadingView)
        contentView.clipsToBounds = true

        loadingView.startAnimating()
        loadingView.hidesWhenStopped = false

        constrain(contentView, loadingView) { contentView, loadingView in
            loadingView.center == contentView.center
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var containerWidth: CGFloat = 320
    var collapsed: Bool = false {
        didSet {
            loadingView.isHidden = collapsed
        }
    }

    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        var newFrame = layoutAttributes.frame
        newFrame.size.height = 24 + (collapsed ? 0 : 64)
        newFrame.size.width = containerWidth
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
}
