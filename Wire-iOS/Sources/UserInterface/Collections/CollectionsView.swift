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
    var collectionViewLayout: CollectionViewLeftAlignedFlowLayout!
    var collectionView: UICollectionView!
    let noItemsLabel = UILabel()
    let noItemsIcon = UIImageView()
    
    static public let useAutolayout = false
    
    var noItemsInLibrary: Bool = false {
        didSet {
            self.noItemsLabel.isHidden = !self.noItemsInLibrary
            self.noItemsIcon.isHidden = !self.noItemsInLibrary
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.recreateLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)

        self.collectionView.register(CollectionImageCell.self, forCellWithReuseIdentifier: CollectionImageCell.reuseIdentifier)
        self.collectionView.register(CollectionFileCell.self, forCellWithReuseIdentifier: CollectionFileCell.reuseIdentifier)
        self.collectionView.register(CollectionAudioCell.self, forCellWithReuseIdentifier: CollectionAudioCell.reuseIdentifier)
        self.collectionView.register(CollectionVideoCell.self, forCellWithReuseIdentifier: CollectionVideoCell.reuseIdentifier)
        self.collectionView.register(CollectionLinkCell.self, forCellWithReuseIdentifier: CollectionLinkCell.reuseIdentifier)
        self.collectionView.register(CollectionLoadingCell.self, forCellWithReuseIdentifier: CollectionLoadingCell.reuseIdentifier)
        self.collectionView.register(CollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CollectionHeaderView.reuseIdentifier)
        self.collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
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
        
        let backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        let placeholderColor = backgroundColor.mix(ColorScheme.default().color(withName: ColorSchemeColorTextForeground), amount: 0.16)
        
        self.noItemsIcon.image = UIImage(for: .library, fontSize: 160, color: placeholderColor)
        self.noItemsLabel.textColor = placeholderColor
    }
    
    private func recreateLayout() {
        let layout = CollectionViewLeftAlignedFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
        if CollectionsView.useAutolayout {
            layout.estimatedItemSize = CGSize(width: 64, height: 64)
        }
        
        self.collectionViewLayout = layout
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
        button.frame = CGRect(x: 0, y: 0, width: 38, height: 20)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
        button.accessibilityIdentifier = "back"
        return button
    }
    
    public static func searchButton() -> IconButton {
        let button = IconButton.iconButtonDefault()
        button.setIcon(.search, with: .tiny, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 38, height: 20)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
        button.accessibilityIdentifier = "search"
        return button
    }
    
    public func constrainViews(searchViewController: TextSearchViewController) {
        self.addSubview(searchViewController.tableView)
        self.addSubview(searchViewController.searchBar)
        
        constrain(self, searchViewController.searchBar, self.collectionView, self.noItemsLabel, self.noItemsIcon) { (selfView: LayoutProxy, searchBar: LayoutProxy, collectionView: LayoutProxy, noItemsLabel: LayoutProxy, noItemsIcon: LayoutProxy) -> () in
            
            searchBar.top == selfView.top
            searchBar.leading == selfView.leading
            searchBar.trailing == selfView.trailing
            searchBar.height == 40
            
            collectionView.top == searchBar.bottom
            
            collectionView.leading == selfView.leading
            collectionView.trailing == selfView.trailing
            collectionView.bottom == selfView.bottom
            
            noItemsLabel.centerX == selfView.centerX
            noItemsLabel.centerY == selfView.centerY + 64
            noItemsLabel.leading >= selfView.leading + 24
            noItemsLabel.trailing <= selfView.trailing - 24
            
            noItemsIcon.centerX == selfView.centerX
            noItemsIcon.bottom == noItemsLabel.top - 24
        }
        
        constrain(self.collectionView, searchViewController.tableView) { collectionView, tableView in
            tableView.edges == collectionView.edges
        }
    }
    
}
