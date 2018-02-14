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

class CreateGroupSection: NSObject, CollectionViewSectionController {
    
    enum Row {
        case createGroup
    }
    
    private let data = [Row.createGroup]
    weak var delegate: CollectionViewSectionDelegate?
    var collectionView: UICollectionView? = nil {
        didSet {
            collectionView?.register(CreateGroupCell.self, forCellWithReuseIdentifier: CreateGroupCell.zm_reuseIdentifier)
        }
    }
    
    var isHidden: Bool {
        return false
    }
    
    func hasSearchResults() -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: CreateGroupCell.zm_reuseIdentifier, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: WAZUIMagic.cgFloat(forIdentifier: "people_picker.search_results_mode.tile_height"))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let top = WAZUIMagic.cgFloat(forIdentifier: "people_picker.search_results_mode.top_padding")
        let left = WAZUIMagic.cgFloat(forIdentifier: "people_picker.search_results_mode.left_padding")
        let right = WAZUIMagic.cgFloat(forIdentifier: "people_picker.search_results_mode.right_padding")
        return UIEdgeInsets(top: top, left: left, bottom: 0, right: right)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.collectionViewSectionController(self, didSelectItem: data[indexPath.row], at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // no-op
    }
    
}
