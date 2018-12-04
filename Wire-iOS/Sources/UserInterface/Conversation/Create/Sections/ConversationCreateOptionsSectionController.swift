//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ConversationCreateOptionsSectionController: NSObject, CollectionViewSectionController {
    
    private enum Item {
        case summary, allowGuests, readReceipts
    }
    
    ///////////////////////////////////////////////////////////////////////
    
    var isHidden: Bool {
        // TODO: John, maybe it's better not to hide the whole section. We could
        // add items depending on team membership, then hide only if there are
        // still some items to show.
        return ZMUser.selfUser().team == nil
    }
    
    // TODO: John, for now let's just show the cells, we can configure it after
    private var items = [Item.allowGuests, .readReceipts]
    
    func prepareForUse(in collectionView: UICollectionView?) {
        // TODO: John, register cells
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // TODO: John, create cell
        return UICollectionViewCell()
    }
}
