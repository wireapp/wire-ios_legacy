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

@objcMembers class ProfileTitleView : UIView {
    
    let verifiedImageView = UIImageView(image: WireStyleKit.imageOfShieldverified)
    let titleLabel = UILabel()
    
    var showVerifiedShield = false {
        didSet {
            updateVerifiedShield()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        verifiedImageView.accessibilityIdentifier = "VerifiedShield"
        
        titleLabel.accessibilityIdentifier = "user_profile.name"
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .clear
        
        addSubview(titleLabel)
        addSubview(verifiedImageView)
    }
    
    private func createConstraints() {
        constrain(self, titleLabel, verifiedImageView) { container, titleLabel, verifiedImageView in
            titleLabel.top == container.top
            titleLabel.bottom == container.bottom
            titleLabel.leading == container.leading
            titleLabel.trailing == container.trailing
            
            verifiedImageView.centerY == titleLabel.centerY
            verifiedImageView.trailing == titleLabel.leading - 16
        }
    }
    
    @objc(configureWithViewModel:)
    public func configure(with model: UserNameDetailViewModel) {
        titleLabel.attributedText = model.title
    }
    
    private func updateVerifiedShield() {
        UIView.transition(
            with: verifiedImageView,
            duration: 0.2,
            options: .transitionCrossDissolve,
            animations: { self.verifiedImageView.isHidden = !self.showVerifiedShield }
        )
    }
    
}
