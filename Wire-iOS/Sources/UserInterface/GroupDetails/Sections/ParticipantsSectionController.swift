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


class ParticipantsSectionController: GroupDetailsSectionController {
    
    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private let participants: [ZMBareUser]
    
    init(participants: [ZMBareUser], delegate: GroupDetailsSectionControllerDelegate) {
        self.participants = participants
        self.delegate = delegate
    }
    
    override func prepareForUse(in collectionView : UICollectionView?) {
        super.prepareForUse(in: collectionView)
        
        collectionView?.register(GroupDetailsParticipantCell.self, forCellWithReuseIdentifier: GroupDetailsParticipantCell.zm_reuseIdentifier)
    }
    
    override var sectionTitle: String {
        return "participants.section.participants".localized(args: participants.count).uppercased()
    }
    
    override var sectionAccessibilityIdentifier: String {
        return "label.groupdetails.participants"
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participants.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = participants[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupDetailsParticipantCell.zm_reuseIdentifier, for: indexPath) as! GroupDetailsParticipantCell
        
        cell.configure(with: user)
        cell.separator.isHidden = (participants.count - 1) == indexPath.row
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = participants[indexPath.row] as? ZMUser else { return }
        delegate?.presentDetails(for: user)
    }
    
}
