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

import UIKit
import Cartography
import WireUtilities

class ListSkeletonCellNameItemView: UIView {
    
    init() {
        super.init(frame: CGRect.zero)
        
        layer.cornerRadius = 4
        backgroundColor = .white
        alpha = 0.16
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ListSkeletonCellView : UIView {
    
    let avatarView : UIView
    let lineView : ListSkeletonCellNameItemView
    
    var lineConstraint : NSLayoutConstraint?
    
    var lineInset : Float {
        set {
            lineConstraint?.constant = -CGFloat(newValue + 16)
        }
        get {
            if let inset = lineConstraint?.constant {
                return -(Float)(inset)
            } else {
                return 0
            }
        }
    }
    
    init() {
        self.avatarView = UIView()
        self.lineView = ListSkeletonCellNameItemView()
        
        super.init(frame: CGRect.zero)
        
        avatarView.layer.cornerRadius = 14
        avatarView.backgroundColor = .white
        avatarView.alpha = 0.16
        
        [avatarView, lineView].forEach(addSubview)
        
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {
        constrain(self, avatarView, lineView) { (containerView, avatarView, lineView) in
            avatarView.width == CGFloat(28)
            avatarView.height == CGFloat(28)
            avatarView.left == containerView.left + 18
            avatarView.top == containerView.top + 18
            avatarView.bottom == containerView.bottom - 17.5
            
            lineView.height == CGFloat(14)
            lineView.left == avatarView.right + 16
            self.lineConstraint = lineView.right == containerView.right
            lineView.centerY == avatarView.centerY
        }
        
        lineInset = 0
    }
    
}

class ListSkeletonCell : UITableViewCell {
    
    static let estimatedHeight = 64.0
    
    private let skeletonCellView : ListSkeletonCellView
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        skeletonCellView = ListSkeletonCellView()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        
        contentView.addSubview(skeletonCellView)
        
        constrain(contentView, skeletonCellView) { (containerView, skeletonCellView) in
            skeletonCellView.edges == containerView.edges
        }
    }
    
    var lineInset : Float {
        set {
            skeletonCellView.lineInset = newValue
        }
        get {
            return skeletonCellView.lineInset
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ListSkeletonContentView : UITableView, UITableViewDataSource {
    
    init() {
        super.init(frame: CGRect.zero, style: .plain)
        
        self.dataSource = self
        self.backgroundColor = .clear
        self.rowHeight = UITableView.automaticDimension
        self.estimatedRowHeight = 28
        self.separatorColor = .clear
        self.isScrollEnabled = false
        self.allowsSelection = false
        
        register(ListSkeletonCell.self, forCellReuseIdentifier: "ListSkeletonCell")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(floor(Double(bounds.size.height) / ListSkeletonCell.estimatedHeight))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: "ListSkeletonCell")
        
        if let skeletonCell = cell as? ListSkeletonCell {
            skeletonCell.lineInset =  Float(arc4random() % 200)
        }
        
        return cell!
    }
    
}

class ListSkeletonView  : UIView {
    
    let titleItem: ListSkeletonCellNameItemView
    let accountView : BaseAccountView
    let listContentView : ListSkeletonContentView
    var buttonRowView : UIStackView!

    init(_ account: Account) {
        self.titleItem = ListSkeletonCellNameItemView()
        self.accountView = AccountViewFactory.viewFor(account: account) as BaseAccountView
        self.listContentView = ListSkeletonContentView()
        
        super.init(frame: CGRect.zero)
        
        accountView.selected = false
        
        buttonRowView = UIStackView(arrangedSubviews: disabledButtons(with: [.person, .archive]))
        buttonRowView.distribution = .equalCentering

        [accountView, titleItem, listContentView, buttonRowView].forEach(addSubview)
        
        createConstraints()
    }
    
    func disabledButtons(with iconTypes: [ZetaIconType]) -> [IconButton] {
        return iconTypes.map { (iconType) in
            let button = IconButton()
            button.setIcon(iconType, with: .tiny, for: .normal)
            button.setIconColor(UIColor.init(white: 1.0, alpha: 0.32), for: .disabled)
            button.isEnabled = false
            return button
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {
        constrain(self, accountView, titleItem, buttonRowView, listContentView) { (containerView, accountView, titleItem, buttonRowView, listContentView) in
            
            accountView.left == containerView.left + 9
            accountView.top == containerView.top + UIScreen.safeArea.top
            
            titleItem.centerY == accountView.centerY
            titleItem.centerX == containerView.centerX
            titleItem.left >= accountView.right
            titleItem.right <= containerView.right
            titleItem.width == 140.0
            titleItem.height == CGFloat(14)
            
            buttonRowView.left == containerView.left + 16
            buttonRowView.right == containerView.right - 16
            buttonRowView.bottom == containerView.bottom - UIScreen.safeArea.bottom
            buttonRowView.height == 55
            
            listContentView.top == accountView.bottom + 10
            listContentView.left == containerView.left
            listContentView.right == containerView.right
            listContentView.bottom == buttonRowView.top
        }
    }
    
}

class SkeletonViewController: UIViewController {
    
    let account : Account
    let backgroundImageView : UIImageView
    let blurEffectView : UIVisualEffectView
    let listView : ListSkeletonView
    let customSplitViewController : SplitViewController
    
    public init(from: Account?, to: Account) {

        if let fromUnwrapped = from, to.imageData == nil, to.teamName == nil {
            account = fromUnwrapped
        }
        else {
            account = to
        }

        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.backgroundImageView = UIImageView()
        self.customSplitViewController = SplitViewController()
        self.listView = ListSkeletonView(account)
        
        super.init(nibName: nil, bundle: nil)
        
        backgroundImageView.contentMode = .scaleAspectFill
        
        let factor = BackgroundViewController.backgroundScaleFactor
        backgroundImageView.transform = CGAffineTransform(scaleX: factor, y: factor)
        
        if let imageData = account.imageData, let image = BackgroundViewController.blurredAppBackground(with: imageData) {
            backgroundImageView.image = image
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        customSplitViewController.view.backgroundColor = .clear
        customSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(customSplitViewController)
        
        [backgroundImageView, blurEffectView, customSplitViewController.view].forEach(self.view.addSubview)

        createConstraints()
        
        customSplitViewController.didMove(toParent: self)
        
        let listViewController = UIViewController()
        listViewController.view = listView
        customSplitViewController.leftViewController = listViewController
        customSplitViewController.view.layoutIfNeeded()
        customSplitViewController .setLeftViewControllerRevealed(true, animated: false, completion: nil)
    }
    
    func createConstraints() {
        constrain(self.view, blurEffectView, backgroundImageView, customSplitViewController.view) { (containerView, blurEffectView, backgroundImageView, splitViewControllerView) in
            blurEffectView.edges == containerView.edges
            splitViewControllerView.edges == containerView.edges
            backgroundImageView.top == containerView.top
            backgroundImageView.left == containerView.left - 100
            backgroundImageView.right == containerView.right + 100
            backgroundImageView.bottom == containerView.bottom
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if customSplitViewController.layoutSize == .compact {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
        }
    }
    
}
