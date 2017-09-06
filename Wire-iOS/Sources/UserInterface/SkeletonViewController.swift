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


class ListSkeletonCellView : UIView {
    
    let avatarView : UIView
    let lineView : UIView
    
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
        self.lineView = UIView()
        
        super.init(frame: CGRect.zero)
        
        avatarView.layer.cornerRadius = 14
        avatarView.backgroundColor = .white
        avatarView.alpha = 0.16
        
        lineView.layer.cornerRadius = 4
        lineView.backgroundColor = .white
        lineView.alpha = 0.16
        
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
            avatarView.left == containerView.left + 16
            avatarView.top == containerView.top
            avatarView.bottom == containerView.bottom - 32
            
            lineView.height == CGFloat(14)
            lineView.left == avatarView.right + 16
            self.lineConstraint = lineView.right == containerView.right
            lineView.centerY == avatarView.centerY
        }
        
        lineInset = 0
    }
    
}

class ListSkeletonCell : UITableViewCell {
    
    static let estimatedHeight = 60.0
    
    private let skeletonCellView : ListSkeletonCellView
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
        self.rowHeight = UITableViewAutomaticDimension
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
            skeletonCell.lineInset =  Float(arc4random() % 100)
        }
        
        return cell!
    }
    
}

class ListSkeletonView  : UIView {
    
    let titleLabel : UILabel
    let accountView : BaseAccountView
    let listContentView : ListSkeletonContentView

    init(_ account: Account) {
        self.titleLabel = UILabel()
        self.accountView = AccountViewFactory.viewFor(account: account) as BaseAccountView
        self.listContentView = ListSkeletonContentView()
        
        super.init(frame: CGRect.zero)
        
        accountView.selected = false
        
        titleLabel.textColor = .white
        titleLabel.font = FontSpec(.medium, .semibold).font
        titleLabel.text = "list.title".localized.uppercased()
        
        let stackView = UIStackView(arrangedSubviews: disabledButtons(with: [.cameraLens, .plus, .compose]))
        stackView.distribution = .equalCentering
        addSubview(stackView)

        [accountView, titleLabel, listContentView, stackView].forEach(addSubview)
        
        constrain(self, accountView, titleLabel, stackView, listContentView) { (containerView, accountView, titleLabel, stackView, listContentView) in
            
            accountView.left == containerView.left + 6
            accountView.top == containerView.top + 16
            
            titleLabel.centerY == accountView.centerY
            titleLabel.centerX == containerView.centerX
            titleLabel.left >= accountView.right
            titleLabel.right <= containerView.right
            
            stackView.left == containerView.left + 16
            stackView.right == containerView.right - 16
            stackView.bottom == containerView.bottom
            stackView.height == 55
            
            listContentView.top == containerView.top + 90
            listContentView.left == containerView.left
            listContentView.right == containerView.right
            listContentView.bottom == stackView.top
        }
        
        createConstraints()
    }
    
    func disabledButtons(with iconTypes: [ZetaIconType]) -> [IconButton] {
        return iconTypes.map { (iconType) in
            let button = IconButton()
            button.setIcon(iconType, with: .tiny, for: .normal)
            button.setIconColor(.white, for: .normal)
            button.isEnabled = false
            return button
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints() {
    }
    
}

class SkeletonViewController: UIViewController {
    
    let account : Account
    let backgroundImageView : UIImageView
    let blurEffectView : UIVisualEffectView
    let listView : ListSkeletonView
    let customSplitViewController : SplitViewController
    
    public init(_ account: Account) {
        self.account = account
        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.backgroundImageView = UIImageView()
        self.customSplitViewController = SplitViewController()
        self.listView = ListSkeletonView(account)
        
        super.init(nibName: nil, bundle: nil)
        
        if let imageData = account.imageData, let image = UIImage(data: imageData) {
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
        addChildViewController(customSplitViewController)
        
        [backgroundImageView, blurEffectView, customSplitViewController.view].forEach(self.view.addSubview)

        createConstraints()
        
        customSplitViewController.didMove(toParentViewController: self)
        
        let listViewController = UIViewController()
        listViewController.view = listView
        customSplitViewController.leftViewController = listViewController
        customSplitViewController.view.layoutIfNeeded()
        customSplitViewController .setLeftViewControllerRevealed(true, animated: false, completion: nil)
    }
    
    func createConstraints() {
        constrain(self.view, blurEffectView, backgroundImageView, customSplitViewController.view) { (containerView, blurEffectView, backgroundImageView, splitViewControllerView) in
            blurEffectView.edges == containerView.edges
            backgroundImageView.edges == containerView.edges
            splitViewControllerView.edges == containerView.edges
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
