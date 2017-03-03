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
import ZMCDataModel
import FLAnimatedImage

@objc public class ImageMessageView: UIView {
    
    private var imageView: FLAnimatedImageView!
    private var userImageView: UserImageView!
    private var userNameLabel: UILabel!
    private var userImageViewContainer: UIView!
    private var dotsLoadingView: ThreeDotsLoadingView!
    
    public func updateForImage() {
        if let message = self.message,
            let imageMessageData = message.imageMessageData,
            let imageData = imageMessageData.imageData {
            
            if (imageMessageData.isAnimatedGIF) {
                self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
            }
            else {
                self.imageView.image = UIImage(data: imageData)
            }
        }
    }
    
    private func createViews() {
        
        self.imageView = FLAnimatedImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        
        self.userImageViewContainer = UIView()
        
        self.userImageView = UserImageView(size: .tiny)
        self.userImageViewContainer.addSubview(self.userImageView)
        
        self.userNameLabel = UILabel()
        
        self.dotsLoadingView = ThreeDotsLoadingView()
        
        [self.imageView, self.userImageViewContainer, self.userNameLabel, self.dotsLoadingView].forEach(self.addSubview)
        
        constrain(self, self.imageView, self.userImageView, self.userImageViewContainer, self.userNameLabel) { selfView, imageView, userImageView, userImageViewContainer, userNameLabel in
            userImageViewContainer.left == selfView.left
            userImageViewContainer.width == 48
            userImageViewContainer.height == 24
            userImageViewContainer.top == selfView.top
            
            userImageView.top == userImageViewContainer.top
            userImageView.bottom == userImageViewContainer.bottom
            userImageView.centerX == userImageViewContainer.centerX
            
            userNameLabel.left == userImageViewContainer.right
            userNameLabel.right == selfView.right
            userNameLabel.centerY == userImageView.centerY
            
            imageView.top == userImageViewContainer.bottom
            imageView.left == userImageViewContainer.right
            imageView.right == selfView.right
            imageView.bottom == selfView.bottom
        }
        
        self.addSubview(self.dotsLoadingView)
        
        constrain(self.imageView, self.dotsLoadingView) { imageView, dotsLoadingView in
            dotsLoadingView.center == imageView.center
            imageView.height >= dotsLoadingView.height + 48
        }
        
        self.updateForImage()
    }
    
    private var user: ZMUser? {
        didSet {
            if let user = self.user {
                self.userNameLabel.textColor = ColorScheme.default().nameAccent(for: user.accentColorValue, variant: .light)
                self.userNameLabel.text = user.displayName
                self.userImageView.user = user
            }
        }
    }

    public var message: ZMAssetClientMessage? {
        didSet {
            if let message = self.message {
                self.user = message.sender
                
                self.updateForImage()
            }
        }
    }
}

