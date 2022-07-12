//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class CustomSearchBar: UITextView {
    var isEditing: Bool = false {
        didSet {
            layer.borderColor = isEditing
            ? style?.activeBorderColor.cgColor
            : style?.borderColor.cgColor
        }
    }
    private var style: SearchBarStyle?
    convenience init(style searchBarStyle: SearchBarStyle) {
        self.init(frame: .zero)
        self.style = searchBarStyle
        self.applyStyle(searchBarStyle)
        self.applyLeftImage(color: SemanticColors.Icon.magnifyingGlassButton)
    }
    init(frame: CGRect) {
        super.init(frame: CGRect.zero, textContainer: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UITextView {
    func applyLeftImage(color col: UIColor) {
        let searchImageView = UIImageView()
        searchImageView.setIcon(
            .search,
            size: .tiny,
            color: .black)
        let searchIcon: UIImage = searchImageView.image!
        searchImageView.frame = CGRect(x: 16.0, y: 12.0, width: searchIcon.size.width, height: searchIcon.size.height)
        searchImageView.contentMode = UIView.ContentMode.center
        self.addSubview(searchImageView)
    }
}
