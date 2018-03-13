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
        case createGuestRoom
    }
    
    private var data: [Row] {
        return ZMUser.selfUser().isTeamMember ? [Row.createGroup, Row.createGuestRoom] : [Row.createGroup]
    }
    
    weak var delegate: SearchSectionControllerDelegate?

    var isHidden: Bool {
        return false
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(CreateGroupCell.self, forCellWithReuseIdentifier: CreateGroupCell.zm_reuseIdentifier)
        collectionView?.register(CreateGuestRoomCell.self, forCellWithReuseIdentifier: CreateGuestRoomCell.zm_reuseIdentifier)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch data[indexPath.row] {
        case .createGroup:
            return collectionView.dequeueReusableCell(withReuseIdentifier: CreateGroupCell.zm_reuseIdentifier, for: indexPath)
        case .createGuestRoom:
            return collectionView.dequeueReusableCell(withReuseIdentifier: CreateGuestRoomCell.zm_reuseIdentifier, for: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch data[indexPath.row] {
        case .createGroup:
            delegate?.searchSectionController(self, didSelectRow: .createGroup, at: indexPath)
        case .createGuestRoom:
            delegate?.searchSectionController(self, didSelectRow: .createGuestRoom, at: indexPath)
        }
        
    }
    
}
