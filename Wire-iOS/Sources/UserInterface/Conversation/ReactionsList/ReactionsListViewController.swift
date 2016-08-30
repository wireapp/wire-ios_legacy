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
import zmessaging
import Cartography

@objc public class ReactionsListViewController: UIViewController {
    public let message: ZMMessage
    public let reactionsUsers: [ZMUser]
    private let collectionViewLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    
    public init(message: ZMMessage) {
        self.message = message
        ///self.reactionsUsers = self.message.likers
        self.reactionsUsers = [ZMUser.selfUser(), ZMUser.selfUser(), ZMUser.selfUser(), ZMUser.selfUser()]
        super.init(nibName: .None, bundle: .None)
        self.title = "content.reactions_list.likers".localized
        let leftArrowImage = UIImage(forIcon: .LeftArrow, iconSize: .Small, color: ColorScheme.defaultColorScheme().colorWithName(ColorSchemeColorIconNormal))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftArrowImage, style: .Plain, target: self, action: #selector(ReactionsListViewController.backPressed(_:)))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.collectionViewLayout.scrollDirection = .Vertical
        self.collectionViewLayout.minimumLineSpacing = 0
        self.collectionViewLayout.minimumInteritemSpacing = 0
        self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionViewLayout)
        self.collectionView.registerClass(ReactionCell.self, forCellWithReuseIdentifier: ReactionCell.reuseIdentifier)
        self.view.backgroundColor = UIColor.whiteColor()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.allowsSelection = true
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.view.addSubview(self.collectionView)
        constrain(self.view, self.collectionView) { selfView, collectionView in
            collectionView.edges == selfView.edges
        }
    }
    
    @objc public func backPressed(button: AnyObject!) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: .None)
    }
}

extension ReactionsListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.reactionsUsers.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SearchResultCell", forIndexPath: indexPath) as! SearchResultCell
        cell.user = self.reactionsUsers[indexPath.item]
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.bounds.width, 44)
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        

    }
}
