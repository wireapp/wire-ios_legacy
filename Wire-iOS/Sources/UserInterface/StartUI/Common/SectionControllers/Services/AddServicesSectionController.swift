//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

protocol AddServicesSectionDelegate: class {
    func addServicesSectionDidRequestOpenServicesAdmin()
}

class AddServicesSectionController: NSObject, CollectionViewSectionController {
    
    weak var delegate: AddServicesSectionDelegate?
    let canSelfUserManageTeam: Bool
    
    init(canSelfUserManageTeam: Bool) {
        self.canSelfUserManageTeam = canSelfUserManageTeam
        super.init()
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(OpenServicesAdminCell.self, forCellWithReuseIdentifier: OpenServicesAdminCell.zm_reuseIdentifier)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    var isHidden: Bool {
        return !canSelfUserManageTeam
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: OpenServicesAdminCell.zm_reuseIdentifier, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.addServicesSectionDidRequestOpenServicesAdmin()
    }
    
}
