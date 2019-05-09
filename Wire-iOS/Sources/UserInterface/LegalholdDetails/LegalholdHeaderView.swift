//
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

class LegalholdHeaderView: UIView {
    
    let iconView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        
        imageView.setIcon(.legalholdactive, size: .large, color: .vividRed)
        
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        
        label.text = "legalhold.header.title".localized
        label.font = UIFont.largeSemiboldFont
        
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        let text = ZMUser.selfUser()?.isUnderLegalhold == true ? "legalhold.header.self_description" : "legalhold.header.other_description"
        
        label.attributedText = text.localized && .paragraphSpacing(8)
        label.font = UIFont.normalFont
        label.numberOfLines = 0
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, descriptionLabel])
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 32
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
