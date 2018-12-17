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

@objcMembers class SearchResultsView : UIView {
    
    let accessoryViewMargin : CGFloat = 16.0
    let emptyResultContainer = UIView()
    let collectionView : UICollectionView
    let collectionViewLayout : UICollectionViewFlowLayout
    let accessoryContainer = UIView()
    var lastLayoutBounds : CGRect = CGRect.zero
    var accessoryContainerHeightConstraint: NSLayoutConstraint?
    var accessoryViewBottomOffsetConstraint : NSLayoutConstraint?
    weak var parentViewController: UIViewController?
    
    init() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsMultipleSelection = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        
        super.init(frame: CGRect.zero)
        
        [collectionView, accessoryContainer, emptyResultContainer].forEach(addSubview)
        
        createConstraints()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {

        [collectionView, accessoryContainer, emptyResultContainer].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        collectionView.fitInSuperview(exclude: .bottom)

        accessoryContainerHeightConstraint = accessoryContainer.heightAnchor.constraint(equalToConstant: 0)
        accessoryViewBottomOffsetConstraint = accessoryContainer.bottomAnchor.constraint(equalTo: bottomAnchor)

        NSLayoutConstraint.activate([
            collectionView.bottomAnchor.constraint(equalTo: accessoryContainer.topAnchor),

            accessoryContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            accessoryContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            accessoryContainerHeightConstraint!,
            accessoryViewBottomOffsetConstraint!,

            emptyResultContainer.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -64),
            emptyResultContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyResultContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            emptyResultContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
            ])
    }
    
    override func layoutSubviews() {
        if !lastLayoutBounds.equalTo(bounds) {
            collectionView.collectionViewLayout.invalidateLayout()
        }
        
        lastLayoutBounds = bounds
        
        super.layoutSubviews()
    }
    
    var accessoryView : UIView? {
        didSet {
            guard oldValue != accessoryView else { return }
            
            oldValue?.removeFromSuperview()
            
            if let accessoryView = accessoryView {
                accessoryContainer.addSubview(accessoryView)
                accessoryContainerHeightConstraint?.isActive = false

                accessoryView.translatesAutoresizingMaskIntoConstraints = false
                accessoryView.fitInSuperview()
            }
            else {
                accessoryContainerHeightConstraint?.isActive = true
            }

            updateContentInset()
        }
    }
    
    var emptyResultView : UIView? {
        didSet {
            guard oldValue != emptyResultView else { return }
            
            oldValue?.removeFromSuperview()
            
            if let emptyResultView = emptyResultView {
                emptyResultContainer.addSubview(emptyResultView)

                emptyResultView.translatesAutoresizingMaskIntoConstraints = false
                emptyResultView.fitInSuperview()
            }
        }
    }
    
    @objc func keyboardFrameDidChange(notification: Notification) {
        if let parentViewController = parentViewController, parentViewController.isContainedInPopover() {
            return
        }
        
        let firstResponder = UIResponder.wr_currentFirst()
        let inputAccessoryHeight = firstResponder?.inputAccessoryView?.bounds.size.height ?? 0
        
        UIView.animate(withKeyboardNotification: notification, in: self, animations: { (keyboardFrameInView) in
            let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight
            self.accessoryViewBottomOffsetConstraint?.constant = -keyboardHeight
            self.layoutIfNeeded()
        }, completion: nil)
    }

    private func updateContentInset() {

        if let accessoryView = self.accessoryView {
            accessoryView.layoutIfNeeded()
            let bottomInset = (UIScreen.hasNotch ? accessoryViewMargin : 0) + accessoryView.frame.height - UIScreen.safeArea.bottom

            // Add padding at the bottom of the screen
            collectionView.contentInset.bottom = bottomInset
            collectionView.scrollIndicatorInsets.bottom  = bottomInset
        } else {
            collectionView.contentInset.bottom = 0
            collectionView.scrollIndicatorInsets.bottom = 0
        }

    }
    
}
