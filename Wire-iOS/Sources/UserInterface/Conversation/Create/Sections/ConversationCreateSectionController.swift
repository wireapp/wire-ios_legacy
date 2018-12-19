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

class ConversationCreateSectionController: NSObject, CollectionViewSectionController {
    
    typealias CreationCell = (DetailsCollectionViewCell & ConversationCreationValuesConfigurable)
    
    var values: ConversationCreationValues

    var isHidden = false

    weak var cell: CreationCell?
    
    var header = UICollectionReusableView(frame: .zero)
    var headerHeight: CGFloat = 0
    
    var footer = SectionFooter(frame: .zero)
    var footerText = ""
    
    init(values: ConversationCreationValues) {
        self.values = values
    }
    
    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(
            SectionFooter.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "SectionFooter")
        
        collectionView?.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader")
    }
    
}

extension ConversationCreateSectionController: ConversationCreationValuesConfigurable {
    func configure(with values: ConversationCreationValues) {
        self.cell?.configure(with: values)
    }
}

extension ConversationCreateSectionController {
    
    // MARK: - Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        assertionFailure("Must be overriden.")
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath)
            return view
        default:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionFooter", for: indexPath)
            (view as? SectionFooter)?.titleLabel.text = footerText
            return view
        }
    }
    
    // MARK: - Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: headerHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        footer.titleLabel.text = footerText
        footer.size(fittingWidth: collectionView.bounds.width)
        return footer.bounds.size
    }
}
