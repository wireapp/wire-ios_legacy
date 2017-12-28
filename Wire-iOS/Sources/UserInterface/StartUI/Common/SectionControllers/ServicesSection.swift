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

public class ServicesSection: NSObject, CollectionViewSectionController {

    public var services: [ServiceUser] = [] {
        didSet {
            self.isHidden = services.isEmpty
        }
    }
    
    public var collectionView: UICollectionView! = nil {
        didSet {
            guard let collectionView = self.collectionView else {
                return
            }
            
            collectionView.register(SearchResultCell.self,
                                    forCellWithReuseIdentifier: ServicesSection.ServicesSectionCellReuseIdentifier)

            collectionView.register(SearchSectionHeaderView.self,
                                    forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                    withReuseIdentifier: PeoplePickerHeaderReuseIdentifier)
        }
    }
    
    public weak var delegate: CollectionViewSectionDelegate? = nil
    
    public static let ServicesSectionCellReuseIdentifier = "ServicesSectionCellReuseIdentifier"
    
    public var isHidden: Bool = false
    
    public let colorSchemeVariant: ColorSchemeVariant
    
    public init(colorSchemeVariant: ColorSchemeVariant) {
        self.colorSchemeVariant = colorSchemeVariant
        super.init()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.services.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                               withReuseIdentifier: PeoplePickerHeaderReuseIdentifier,
                                                                               for: indexPath) as? SearchSectionHeaderView else {
            fatal("cannot dequeue header")
        }
        headerView.title = "peoplepicker.header.services".localized
        headerView.clipsToBounds = true
        headerView.colorSchemeVariant = colorSchemeVariant
        return headerView
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ServicesSection.ServicesSectionCellReuseIdentifier,
                                                            for: indexPath) as? SearchResultCell
        else {
            fatal("cannot dequeue cell")
        }
        
        let user = self.services[indexPath.item]
        cell.user = user
        cell.colorSchemeVariant = colorSchemeVariant
        cell.doubleTapAction = { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.collectionViewSectionController(self, didDoubleTapItem: user, at: indexPath)
        }
        cell.instantConnectAction = { [weak self] _ in
            self?.delegate?.collectionViewSectionController(self, didSelectItem: user, at: indexPath)
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        let item = self.services[indexPath.item]
        self.delegate?.collectionViewSectionController(self, didSelectItem: item, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let item = self.services[indexPath.item]
        self.delegate?.collectionViewSectionController(self, didDeselectItem: item, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.bounds.size.width, height: 40)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.bounds.size.width, height: 52)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}
