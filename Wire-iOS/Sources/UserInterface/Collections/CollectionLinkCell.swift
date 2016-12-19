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

final public class CollectionLinkCell: UICollectionViewCell, Reusable {
    private let articleView = ArticleView(withImagePlaceholder: true)

    public var message: ZMConversationMessage? {
        didSet {
            guard let message = self.message, let textMessageData = message.textMessageData else {
                return
            }
            articleView.configure(withTextMessageData: textMessageData, obfuscated: false)
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
    
    func loadView() {
        self.layoutMargins = UIEdgeInsetsMake(4, 4, 4, 4)
        
        self.articleView.delegate = self
        self.contentView.addSubview(self.articleView)
        
        constrain(self.contentView, self.articleView) { contentView, articleView in
            articleView.edges == contentView.edgesWithinMargins
        }
    }
    
    var isHeightCalculated: Bool = false
    var containerWidth: CGFloat = 320
    
    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isHeightCalculated {
            setNeedsLayout()
            layoutIfNeeded()
            var desiredSize = layoutAttributes.size
            desiredSize.width = self.containerWidth
            let size = contentView.systemLayoutSizeFitting(desiredSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
            var newFrame = layoutAttributes.frame
            newFrame.size.height = CGFloat(ceilf(Float(size.height)))
            layoutAttributes.frame = newFrame
            isHeightCalculated = true
        }
        return layoutAttributes
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.message = .none
        self.isHeightCalculated = false
    }
}

extension CollectionLinkCell: ArticleViewDelegate {
    func articleViewWantsToOpenURL(_ articleView: ArticleView, url: URL) {
        url.open()
    }
    
    func articleViewDidLongPressView(_ articleView: ArticleView) {
        // TODO: showing menu
    }
}
