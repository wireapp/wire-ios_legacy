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

protocol CollectionViewSectionController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var isHidden: Bool { get }
    
    func prepareForUse(in collectionView : UICollectionView?)
    
}

class SectionCollectionViewController: NSObject {
    
    var collectionView : UICollectionView? = nil {
        didSet {
            collectionView?.dataSource = self
            collectionView?.delegate = self
            
            sections.forEach {
                $0.prepareForUse(in: collectionView)
            }
            
            collectionView?.reloadData()
        }
    }
    
    var sections: [CollectionViewSectionController] {
        didSet {
            sections.forEach {
                $0.prepareForUse(in: collectionView)
            }
            
            collectionView?.reloadData()
        }
    }
    
    var visibleSections: [CollectionViewSectionController] {
        return sections.filter({ !$0.isHidden })
    }
    
    init(sections : [CollectionViewSectionController] = []) {
        self.sections = sections
    }
    
}

extension SectionCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        visibleSections[indexPath.section].collectionView?(collectionView, didSelectItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        visibleSections[indexPath.section].collectionView?(collectionView, didDeselectItemAt: indexPath)
    }
    
}

extension SectionCollectionViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        visibleSections[indexPath.section].collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleSections[section].collectionView(collectionView, numberOfItemsInSection: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return visibleSections[indexPath.section].collectionView(collectionView, cellForItemAt:indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return visibleSections[indexPath.section].collectionView!(collectionView, viewForSupplementaryElementOfKind:kind, at:indexPath)
    }
    
}

extension SectionCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return visibleSections[section].collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section) ?? CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return visibleSections[indexPath.section].collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? CGSize.zero
    }
    
}
