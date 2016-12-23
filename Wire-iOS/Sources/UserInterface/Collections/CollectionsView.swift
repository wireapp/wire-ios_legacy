//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography

@objc public final class CollectionsView: UIView {
    let collectionViewLayout = CollectionViewLeftAlignedFlowLayout()
    var collectionView: UICollectionView
    let noItemsLabel = UILabel()
    let noItemsIcon = UIImageView(image: UIImage(for: .library, fontSize: 160, color: UIColor.lightGray))
    
    var noItemsInLibrary: Bool = false {
        didSet {
            self.noItemsLabel.isHidden = !self.noItemsInLibrary
            self.noItemsIcon.isHidden = !self.noItemsInLibrary
        }
    }
    
    override init(frame: CGRect) {
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)

        super.init(frame: frame)
        
        self.collectionViewLayout.scrollDirection = .vertical
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.collectionViewLayout.estimatedItemSize = CGSize(width: 320, height: 64)
        self.collectionView.register(CollectionImageCell.self, forCellWithReuseIdentifier: CollectionImageCell.reuseIdentifier)
        self.collectionView.register(CollectionFileCell.self, forCellWithReuseIdentifier: CollectionFileCell.reuseIdentifier)
        self.collectionView.register(CollectionAudioCell.self, forCellWithReuseIdentifier: CollectionAudioCell.reuseIdentifier)
        self.collectionView.register(CollectionVideoCell.self, forCellWithReuseIdentifier: CollectionVideoCell.reuseIdentifier)
        self.collectionView.register(CollectionLinkCell.self, forCellWithReuseIdentifier: CollectionLinkCell.reuseIdentifier)
        self.collectionView.register(CollectionLoadingCell.self, forCellWithReuseIdentifier: CollectionLoadingCell.reuseIdentifier)
        self.collectionView.register(CollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CollectionHeaderView.reuseIdentifier)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.isScrollEnabled = true
        self.collectionView.backgroundColor = UIColor.clear
        self.addSubview(self.collectionView)

        self.noItemsLabel.accessibilityLabel = "no items"
        self.noItemsLabel.text = "collections.section.no_items".localized.uppercased()
        self.noItemsLabel.numberOfLines = 0
        self.noItemsLabel.isHidden = true
        self.addSubview(self.noItemsLabel)
        self.noItemsIcon.isHidden = true
        self.addSubview(self.noItemsIcon)
        
        self.constrainViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func closeButton() -> IconButton {
        let button = IconButton.iconButtonDefault()
        button.setIcon(.X, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        button.accessibilityIdentifier = "close"
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -16)
        return button
    }
    
    public static func backButton() -> IconButton {
        let button = IconButton.iconButtonDefault()
        button.setIcon(.backArrow, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        button.accessibilityIdentifier = "back"
        return button
    }
    
    private func constrainViews() {
        constrain(self, self.collectionView, self.noItemsLabel, self.noItemsIcon) { (selfView: LayoutProxy, collectionView: LayoutProxy, noItemsLabel: LayoutProxy, noItemsIcon: LayoutProxy) -> () in
            collectionView.edges == selfView.edges
            noItemsLabel.centerX == selfView.centerX
            noItemsLabel.centerY == selfView.centerY + 64
            noItemsLabel.left >= selfView.left + 24
            noItemsLabel.right <= selfView.right - 24
            
            noItemsIcon.centerX == selfView.centerX
            noItemsIcon.bottom == noItemsLabel.top - 24
        }
    }
    
}
