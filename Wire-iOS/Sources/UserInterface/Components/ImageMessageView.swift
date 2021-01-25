//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel
import FLAnimatedImage

final class ImageMessageView: UIView {
    
    private let imageView = FLAnimatedImageView()
    private let userImageView = UserImageView(size: .tiny)
    private let userNameLabel = UILabel()
    private let userImageViewContainer = UIView()
    private let dotsLoadingView = ThreeDotsLoadingView()
    private var aspectRatioConstraint: NSLayoutConstraint? = .none
    private var imageSize: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createViews()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var user: UserType? {
        didSet {
            if let user = self.user {
                
                self.userNameLabel.textColor = UIColor.nameColor(for: user.accentColorValue, variant: .light)
                self.userNameLabel.text = user.name
                self.userImageView.user = user
            }
        }
    }
    
    var message: ZMConversationMessage? {
        didSet {
            if let message = self.message {
                user = message.senderUser
                
                updateForImage()
            }
        }
    }
    
    func updateForImage() {
        if let message = self.message,
            let imageMessageData = message.imageMessageData,
            let imageData = imageMessageData.imageData,
            imageData.count > 0 {
            
            self.dotsLoadingView.stopProgressAnimation()
            self.dotsLoadingView.isHidden = true
            
            if (imageMessageData.isAnimatedGIF) {
                let image = FLAnimatedImage(animatedGIFData: imageData)
                self.imageSize = image?.size ?? .zero
                self.imageView.animatedImage = image
            }
            else {
                let image = UIImage(data: imageData, scale: 2.0)
                self.imageSize = image?.size ?? .zero
                self.imageView.image = image
            }
        }
        else {
            self.dotsLoadingView.isHidden = false
            self.dotsLoadingView.startProgressAnimation()
        }
        self.updateImageLayout()
    }
    
    private func updateImageLayout() {
        guard self.bounds.width != 0, self.aspectRatioConstraint == .none, self.imageSize.width != 0 else {
            return
        }
        
        if self.imageSize.width / 2.0 > self.imageView.bounds.width {

            constrain(self.imageView) { imageView in
                self.aspectRatioConstraint = imageView.height == imageView.width * (self.imageSize.height / self.imageSize.width)
            }
        }
        else {
            self.imageView.contentMode = .left

            constrain(self.imageView) { imageView in
                self.aspectRatioConstraint = imageView.height == self.imageSize.height
            }
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    private func createViews() {
        
        self.userImageViewContainer.addSubview(self.userImageView)
        
        [self.imageView, self.userImageViewContainer, self.userNameLabel].forEach(self.addSubview)
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        
        self.userNameLabel.font = UIFont.systemFont(ofSize: 12, contentSizeCategory: .small, weight: .medium)
        self.userImageView.initialsFont = UIFont.systemFont(ofSize: 11, contentSizeCategory: .small, weight: .light)

        constrain(self, self.imageView, self.userImageView, self.userImageViewContainer, self.userNameLabel) { selfView, imageView, userImageView, userImageViewContainer, userNameLabel in
            userImageViewContainer.leading == selfView.leading
            userImageViewContainer.width == 48
            userImageViewContainer.height == 24
            userImageViewContainer.top == selfView.top
            
            userImageView.top == userImageViewContainer.top
            userImageView.bottom == userImageViewContainer.bottom
            userImageView.centerX == userImageViewContainer.centerX
            userImageView.width == userImageViewContainer.height
            
            userNameLabel.leading == userImageViewContainer.trailing
            userNameLabel.trailing <= selfView.trailing
            userNameLabel.centerY == userImageView.centerY
            
            imageView.top == userImageViewContainer.bottom + 12
            imageView.leading == userImageViewContainer.trailing
            imageView.trailing == selfView.trailing
            selfView.bottom == imageView.bottom
            imageView.height >= 64
        }
        
        self.addSubview(self.dotsLoadingView)
        
        constrain(self, self.dotsLoadingView) { selfView, dotsLoadingView in
            dotsLoadingView.center == selfView.center
        }
        
        self.updateForImage()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateImageLayout()
    }
}

