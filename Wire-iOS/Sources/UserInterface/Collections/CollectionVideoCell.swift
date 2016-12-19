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

final public class CollectionVideoCell: UICollectionViewCell, Reusable {
    private let videoMessageView = VideoMessageView()
    public weak var delegate: TransferViewDelegate? {
        didSet {
            self.videoMessageView.delegate = self.delegate
        }
    }
    public var message: ZMConversationMessage? {
        didSet {
            guard let message = self.message else {
                return
            }
            videoMessageView.configure(for: message, isInitial: true)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }
    
    var isHeightCalculated: Bool = false
    var containerWidth: CGFloat = 320
    
    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isHeightCalculated {
            setNeedsLayout()
            layoutIfNeeded()
            var desiredSize = layoutAttributes.size
            desiredSize.width = self.containerWidth
            let size = contentView.systemLayoutSizeFitting(desiredSize)
            var newFrame = layoutAttributes.frame
            newFrame.size.height = CGFloat(ceilf(Float(size.height)))
            layoutAttributes.frame = newFrame
            isHeightCalculated = true
        }
        return layoutAttributes
    }
    
    func loadView() {
        self.videoMessageView.delegate = self.delegate
        self.contentView.addSubview(self.videoMessageView)
        
        constrain(self, self.videoMessageView) { selfView, videoMessageView in
            videoMessageView.edges == selfView.edges
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
        self.isHeightCalculated = false
    }
}
