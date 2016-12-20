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

final class CollectionViewLeftAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let oldAttributes: [UICollectionViewLayoutAttributes] = super.layoutAttributesForElements(in: rect) else {
            return .none
        }
        
        var newAttributes: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()

        for attributes: UICollectionViewLayoutAttributes in oldAttributes {
            let cellIsFullWidth = abs(attributes.frame.size.width - (rect.width - self.sectionInset.left - self.sectionInset.right)) <= 1
            if attributes.frame.origin.x != self.sectionInset.left && cellIsFullWidth {
                var newLeftAlignedFrame: CGRect = attributes.frame
                newLeftAlignedFrame.origin.x = self.sectionInset.left
                attributes.frame = newLeftAlignedFrame
            }
            
            newAttributes.append(attributes)
        }
        return newAttributes
    }
}
