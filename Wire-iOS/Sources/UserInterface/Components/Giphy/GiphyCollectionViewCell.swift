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

import UIKit
import Cartography
import Ziphy
import FLAnimatedImage

final class GiphyCollectionViewCell: UICollectionViewCell {

    static let CellIdentifier = "GiphyCollectionViewCell"

    let imageView = FLAnimatedImageView()
    var ziph: Ziph?
    var representation: ZiphyAnimatedImage?

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)

        constrain(contentView, imageView) { contentView, imageView in
            imageView.edges == contentView.edges
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        imageView.animatedImage = nil
        ziph = nil
        representation = nil
        backgroundColor = nil
    }

}
