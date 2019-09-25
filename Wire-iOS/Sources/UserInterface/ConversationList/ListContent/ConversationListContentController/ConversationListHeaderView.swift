
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class ConversationListHeaderView: UICollectionReusableView {
    var isCollapsed = false {
        didSet {
            ///TODO: update icon
            ///TODO: VM
        }
    }
    
    var desiredWidth: CGFloat = 0
    var desiredHeight: CGFloat = 0

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .white

        return label
    }()
    
    ///TODO: arraw icon animation?
    let arrowIconImageView: UIImageView = {
        let image = StyleKitIcon.downArrow.makeImage(size: 10, color: .white)
        
        let imageView = UIImageView(image: image)
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        [titleLabel, arrowIconImageView].forEach(addSubview)

        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [titleLabel, arrowIconImageView, self].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            arrowIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat.ConversationList.horizontalMargin),
            arrowIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: arrowIconImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)])
    }

    override public var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: desiredWidth,
                          height: desiredHeight)
        }
    }
}
