//
//  MentionsSearchResultCell.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 12.09.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Cartography

class MentionsSearchResultCell: UITableViewCell {

    let profilePicture = UserImageView(size: .small)
    let nameLabel = UILabel(frame: .zero)
    let handleLabel = UILabel(frame: .zero)
    let labelsContainer = UIView(frame: .zero)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with user: ZMUser) {
        
        profilePicture.user = user
        nameLabel.text = user.displayName
        
        if let handle = user.handle {
            handleLabel.text = "@" + handle
        } else {
            handleLabel.text =  ""
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        profilePicture.accessibilityIdentifier = "user's profile picture"
        nameLabel.accessibilityIdentifier = "user's name"
        handleLabel.accessibilityIdentifier = "user's handle"
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [self.nameLabel, self.handleLabel].forEach(self.labelsContainer.addSubview)
        [self.profilePicture, self.labelsContainer].forEach(self.contentView.addSubview)
        
        let margin: CGFloat = 16.0
        
        constrain(self.contentView, self.labelsContainer, self.profilePicture, self.nameLabel, self.handleLabel) {
            contentView, labelsContainer, profilePicture, nameLabel, handleLabel in
            
            profilePicture.leading == contentView.leading + margin
            profilePicture.centerY == contentView.centerY
            
            labelsContainer.leading == profilePicture.trailing + margin
            labelsContainer.centerY == contentView.centerY
            labelsContainer.trailing <= contentView.trailing - margin
            
            nameLabel.top == labelsContainer.top
            nameLabel.leading == labelsContainer.leading
            nameLabel.trailing == labelsContainer.trailing // <=
            
            handleLabel.top == nameLabel.bottom + 2
            handleLabel.leading == labelsContainer.leading
            handleLabel.trailing == labelsContainer.trailing // <=
            handleLabel.bottom == labelsContainer.bottom
        }
        
        
        self.backgroundColor = UIColor.clear
        self.backgroundView = UIView()
        self.selectedBackgroundView = UIView()
        
        nameLabel.font = .normalFont
        handleLabel.font = .smallFont
    }
    
    var variant: ColorSchemeVariant? {
        didSet {
            guard let variant = variant else { return }
            nameLabel.textColor = UIColor(scheme: .textForeground, variant: variant)
            handleLabel.textColor = UIColor(scheme: .textDimmed, variant: variant)
            self.backgroundColor = UIColor(scheme: .background, variant: variant)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
