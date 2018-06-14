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

open class AssetCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    let durationView = UILabel()
    
    var imageRequestTag: PHImageRequestID = PHInvalidImageRequestID
    var representedAssetIdentifier: String!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.clipsToBounds = true
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        self.contentView.addSubview(self.imageView)
        
        self.durationView.textAlignment = .center
        self.durationView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.durationView.textColor = UIColor.white
        self.durationView.font = FontSpec(.small, .light).font!
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
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        return options
    }()
    
    var asset: PHAsset? {
        didSet {
            self.imageView.image = nil

            let manager = PHImageManager.default()
            
            if self.imageRequestTag != PHInvalidImageRequestID {
                manager.cancelImageRequest(self.imageRequestTag)
                self.imageRequestTag = PHInvalidImageRequestID
            }
            
            guard let asset = self.asset else {
                self.durationView.text = ""
                self.durationView.isHidden = true
                return
            }
            
            let maxDimensionRetina = max(self.bounds.size.width, self.bounds.size.height) * (self.window ?? UIApplication.shared.keyWindow!).screen.scale

            representedAssetIdentifier = asset.localIdentifier
            imageRequestTag = manager.requestImage(for: asset,
                                                   targetSize: CGSize(width: maxDimensionRetina, height: maxDimensionRetina),
                                                   contentMode: .aspectFill,
                                                   options: type(of: self).imageFetchOptions,
                                                   resultHandler: { [weak self] result, info -> Void in
                                                    guard let `self` = self,
                                                        self.representedAssetIdentifier == asset.localIdentifier
                                                        else { return }
                                                    self.imageView.image = result
            })
            
            if asset.mediaType == .video {
                let duration = Int(ceil(asset.duration))
                
                let (seconds, minutes) = (duration % 60, duration / 60)
                self.durationView.text = String(format: "%d:%02d", minutes, seconds)
                self.durationView.isHidden = false
            }
            else {
                self.durationView.text = ""
                self.durationView.isHidden = true
            }
        }
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        
        self.asset = .none
    }
}
