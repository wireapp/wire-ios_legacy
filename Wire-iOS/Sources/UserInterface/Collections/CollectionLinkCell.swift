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

final public class CollectionLinkCell: CollectionCell {
    private var articleView: ArticleView? = .none

    func createArticleView(withImagePlaceholder: Bool) -> ArticleView {
        let articleView = ArticleView(withImagePlaceholder: withImagePlaceholder)
        articleView.delegate = self
        self.contentView.addSubview(articleView)
        self.contentView.layoutMargins = UIEdgeInsetsMake(4, 16, 4, 16)
        
        constrain(self.contentView, articleView) { contentView, articleView in
            articleView.edges == contentView.edgesWithinMargins
        }
        
        self.articleView = articleView
        return articleView
    }

    override func updateForMessage(changeInfo: MessageChangeInfo?) {
        super.updateForMessage(changeInfo: changeInfo)
        
        guard let message = self.message, let textMessageData = message.textMessageData else {
            return
        }
        
        message.requestImageDownload()
        
        self.articleView = nil
        
        self.createArticleView(withImagePlaceholder: textMessageData.hasImageData).configure(withTextMessageData: textMessageData, obfuscated: false)
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
            newFrame.size.width = self.containerWidth
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
