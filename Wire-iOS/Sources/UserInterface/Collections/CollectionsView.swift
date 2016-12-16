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

final class CollectionsView: UIView {
    let collectionViewLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView
    
    let blurView = { () -> UIVisualEffectView in
        let effect = UIBlurEffect(style: .light)

        return UIVisualEffectView(effect: effect)
    }()
    
    let navigationBar = UINavigationBar()
    
    override init(frame: CGRect) {
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)

        super.init(frame: frame)
        
        self.navigationBar.isTranslucent = false
        self.navigationBar.isOpaque = true
        self.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.navigationBar)
        
        self.addSubview(self.blurView)
        
        self.collectionViewLayout.scrollDirection = .vertical
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(16, 0, 16, 0)
        self.collectionView.register(CollectionImageCell.self, forCellWithReuseIdentifier: CollectionImageCell.reuseIdentifier)
        self.collectionView.register(CollectionFileCell.self, forCellWithReuseIdentifier: CollectionFileCell.reuseIdentifier)
        self.collectionView.register(CollectionAudioCell.self, forCellWithReuseIdentifier: CollectionAudioCell.reuseIdentifier)
        self.collectionView.register(CollectionVideoCell.self, forCellWithReuseIdentifier: CollectionVideoCell.reuseIdentifier)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.isScrollEnabled = true
        self.collectionView.backgroundColor = UIColor.clear
        
        self.addSubview(self.collectionView)
        
        self.constrainViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func constrainViews() {
        constrain(self, self.navigationBar, self.blurView, self.collectionView) { (selfView: LayoutProxy, navigationBar: LayoutProxy, blurView: LayoutProxy, collectionView: LayoutProxy) -> () in
            navigationBar.left == selfView.left
            navigationBar.right == selfView.right
            navigationBar.top == selfView.top
            
            navigationBar.height == 64
            
            blurView.top == navigationBar.bottom
            blurView.left == selfView.left
            blurView.right == selfView.right
            blurView.bottom == selfView.bottom
            
            collectionView.edges == blurView.edges
        }
    }
    
}
