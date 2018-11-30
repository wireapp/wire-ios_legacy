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

class ConversationCreateErrorSectionController: NSObject, CollectionViewSectionController {
    
    typealias Cell = ConversationCreateErrorCell
    
    weak var errorCell: Cell?
    
    var isHidden: Bool {
        return false
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView.flatMap(Cell.register)
    }
    
    func clearError() {
        errorCell?.label.text = nil
    }
    
    func displayError(_ error: Error) {
        errorCell?.label.text = error.localizedDescription.uppercased()

    }
}

extension ConversationCreateErrorSectionController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: Cell.self, for: indexPath)
        errorCell = cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
}

