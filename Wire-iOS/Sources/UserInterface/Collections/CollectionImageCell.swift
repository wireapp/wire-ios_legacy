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
import WireExtensionComponents

private let zmLog = ZMSLog(tag: "UI")

final public class CollectionImageCell: CollectionCell {
    
    static let maxCellSize: CGFloat = 100

    override var message: ZMConversationMessage? {
        didSet {
            loadImage()
        }
    }
        
    private let imageView = FLAnimatedImageView()
    private let loadingView = ThreeDotsLoadingView()
    
    /// This token is changes everytime the cell is re-used. Useful when performing
    /// asynchronous tasks where the cell might have been re-used in the mean time.
    private var reuseToken = UUID()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }
    
    var isHeightCalculated: Bool = false
    
    func loadView() {
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.imageView.accessibilityIdentifier = "image"
        self.loadingView.accessibilityIdentifier = "loading"
        self.secureContentsView.addSubview(self.imageView)
        self.secureContentsView.addSubview(self.loadingView)
        constrain(self, self.imageView, self.loadingView) { selfView, imageView, loadingView in
            imageView.left == selfView.left
            imageView.right == selfView.right
            imageView.top == selfView.top
            imageView.bottom == selfView.bottom
            loadingView.center == selfView.center
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
        self.isHeightCalculated = false
        self.reuseToken = UUID()
    }

    override var obfuscationIcon: ZetaIconType {
        return .photo
    }
    
    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)
        
        guard let changeInfo = changeInfo, changeInfo.imageChanged else { return }
        
        loadImage()
    }
    
    override func menuConfigurationProperties() -> MenuConfigurationProperties? {
        guard let properties = super.menuConfigurationProperties() else {
            return .none
        }
        
        var mutableItems = properties.additionalItems ?? []
        
        let saveItem = UIMenuItem(title: "content.image.save_image".localized, action: #selector(CollectionImageCell.save(_:)))
        mutableItems.append(saveItem)
        
        properties.additionalItems = mutableItems
        return properties
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(CollectionImageCell.save(_:)): fallthrough
        case #selector(copy(_:)):
            return true
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    override public func copy(_ sender: Any?) {
        guard let imageData = self.message?.imageMessageData?.imageData else {
            return
        }
        
        UIPasteboard.general.setMediaAsset(UIImage(data: imageData))
    }
    
    var saveableImage : SavableImage?
    
    @objc func save(_ sender: AnyObject!) {
        guard let imageMessageData = self.message?.imageMessageData else { return }
        
        saveableImage = SavableImage(data: imageMessageData.imageData, isGIF: imageMessageData.isAnimatedGIF)
        saveableImage?.saveToLibrary { [weak self] _ in
            self?.saveableImage = nil
        }
    }

    fileprivate func loadImage() {
        guard let message = self.message, message.imageMessageData != nil else {
            self.imageView.image = .none
            return
        }
        
        imageView.isHidden = true
        loadingView.isHidden = false
        
        let token = reuseToken
        
        message.fetchImage(sizeLimit: .maxDimensionForShortSide(CollectionImageCell.maxCellSize * UIScreen.main.scale)) { [weak self] (image) in
            guard token == self?.reuseToken else { return }
            
            self?.imageView.setMediaAsset(image)
            self?.imageView.isHidden = false
            self?.loadingView.isHidden = true
        }
    }
}

