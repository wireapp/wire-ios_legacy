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

class ConversationCreateGuestsSectionController: NSObject, CollectionViewSectionController {
    
    typealias Cell = ConversationCreateGuestsCell

    var isHidden: Bool = false
    var toggleAction: Cell.ToggleHandler?
    
    private weak var guestsCell: Cell?
    
    private var header = SectionHeader(frame: .zero)
    private let headerText = ""
    
    private var footer = SectionFooter(frame: .zero)
    private let footerText = "conversation.create.guests.subtitle".localized
    
    private var values: ConversationCreationValues
    
    init(values: ConversationCreationValues) {
        self.values = values
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView.flatMap(Cell.register)
        
        collectionView?.register(
            SectionFooter.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "SectionFooter")
        
        collectionView?.register(
            SectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader")
    }

}

extension ConversationCreateGuestsSectionController: ConversationCreationValuesConfigurable {
    func configure(with values: ConversationCreationValues) {
        guestsCell?.configure(with: values)
    }
}

extension ConversationCreateGuestsSectionController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: Cell.self, for: indexPath)
        cell.setUp()
        cell.action = toggleAction
        cell.configure(with: values)
        guestsCell = cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath)
            (view as? SectionHeader)?.titleLabel.text = headerText
            return view
        default:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionFooter", for: indexPath)
            (view as? SectionFooter)?.titleLabel.text = footerText
            return view
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        footer.titleLabel.text = footerText
        return footer.sized(fittingWidth: collectionView.bounds.width).bounds.size
    }
}
