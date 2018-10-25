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
import Cartography

class MessageDeletedCell: ConversationCell {
    
    let trashImageView = UIImageView()
    
    var trashColor: UIColor? = UIColor(scheme: .iconNormal)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        trashImageView.image = trashColor.map {
            UIImage(for: .trash, iconSize: .messageStatus, color: $0)
        }
        contentView.addSubview(trashImageView)
    }
    
    func createConstraints() {
        constrain(authorLabel, trashImageView, messageContentView) { authorLabel, imageView, messageContent in
            imageView.centerY == authorLabel.centerY
            imageView.left == authorLabel.right + 8
        }
    }
}
