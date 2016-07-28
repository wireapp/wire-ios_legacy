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
import Photos
import Cartography

public class AssetCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let durationView = UILabel()
    
    var imageRequestTag: PHImageRequestID = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.clipsToBounds = true
        
        self.imageView.contentMode = .ScaleAspectFill
        self.imageView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        self.contentView.addSubview(self.imageView)
        
        self.durationView.textAlignment = .Center
        self.durationView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.durationView.textColor = UIColor.whiteColor()
        self.durationView.font = UIFont(magicIdentifier: "style.text.small.font_spec_light")
        self.contentView.addSubview(self.durationView)
        
        constrain(self.contentView, self.imageView, self.durationView) { contentView, imageView, durationView in
            imageView.edges == contentView.edges
            durationView.bottom == contentView.bottom
            durationView.left == contentView.left
            durationView.right == contentView.right
            durationView.height == 20
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let imageFetchOptions: PHImageRequestOptions = {
        let options: PHImageRequestOptions = PHImageRequestOptions()
        options.deliveryMode = .Opportunistic
        options.resizeMode = .Fast
        options.synchronous = false
        return options
    }()
    
    var asset: PHAsset? {
        didSet {
            self.imageView.image = nil

            let manager = PHImageManager.defaultManager()
            
            if self.imageRequestTag != 0 {
                manager.cancelImageRequest(self.imageRequestTag)
                self.imageRequestTag = 0
            }
            
            guard let asset = self.asset else {
                self.durationView.text = ""
                self.durationView.hidden = true
                return
            }
            
            let maxDimensionRetina = max(self.bounds.size.width, self.bounds.size.height) * (self.window ?? UIApplication.sharedApplication().keyWindow!).screen.scale
            self.imageRequestTag = manager.requestImageForAsset(asset,
                                                                 targetSize: CGSizeMake(maxDimensionRetina, maxDimensionRetina),
                                                                 contentMode: .AspectFill,
                                                                 options: self.dynamicType.imageFetchOptions,
                                                                 resultHandler: { [weak self] result, info -> Void in
                                                                    guard let `self` = self,
                                                                        let requesId = info?[PHImageResultRequestIDKey] as? Int
                                                                        else {
                                                                        return
                                                                    }
                                                                    
                                                                    if requesId == Int(self.imageRequestTag) {
                                                                        self.imageView.image = result
                                                                    }
            })
            
            if asset.mediaType == .Video {
                let duration = Int(ceil(asset.duration))
                
                let (seconds, minutes) = (duration % 60, duration / 60)
                self.durationView.text = String(format: "%d:%02d", minutes, seconds)
                self.durationView.hidden = false
            }
            else {
                self.durationView.text = ""
                self.durationView.hidden = true
            }
        }
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        self.asset = .None
    }
    
    static var reuseIdentifier: String {
        return "\(self)"
    }
    
    override public var reuseIdentifier: String? {
        return self.dynamicType.reuseIdentifier
    }
}
