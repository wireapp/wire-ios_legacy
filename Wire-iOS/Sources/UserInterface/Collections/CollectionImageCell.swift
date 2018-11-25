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
        
    private let imageView = ImageResourceView()
    
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
        self.imageView.imageSizeLimit = .maxDimensionForShortSide(CollectionImageCell.maxCellSize * UIScreen.main.scale)
        self.secureContentsView.addSubview(self.imageView)
        constrain(self, self.imageView) { selfView, imageView in
            imageView.left == selfView.left
            imageView.right == selfView.right
            imageView.top == selfView.top
            imageView.bottom == selfView.bottom
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

    var saveableImage : SavableImage?
    
    @objc func save(_ sender: AnyObject!) {
        guard let imageMessageData = self.message?.imageMessageData, let imageData = imageMessageData.imageData else { return }
        
        saveableImage = SavableImage(data: imageData, isGIF: imageMessageData.isAnimatedGIF)
        saveableImage?.saveToLibrary { [weak self] _ in
            self?.saveableImage = nil
        }
    }

    fileprivate func loadImage() {
        imageView.imageResource = message?.imageMessageData?.image
    }
}

