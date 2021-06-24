//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireCommonComponents
import WireDataModel

final class ListSkeletonCellNameItemView: UIView {

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

final class ListSkeletonCellView: UIView {

    let avatarView: UIView
    let lineView: ListSkeletonCellNameItemView

    var lineConstraint: NSLayoutConstraint?

    var lineInset: Float {
        get {
            if let inset = lineConstraint?.constant {
                return -(Float)(inset)
            } else {
                return 0
            }
        }

        set {
            lineConstraint?.constant = -CGFloat(newValue + 16)
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

final class ListSkeletonCell: UITableViewCell {

    static let estimatedHeight = 64.0

    private let skeletonCellView: ListSkeletonCellView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        skeletonCellView = ListSkeletonCellView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = .clear

        contentView.addSubview(skeletonCellView)

        constrain(contentView, skeletonCellView) { (containerView, skeletonCellView) in
            skeletonCellView.edges == containerView.edges
        }
    }

    var lineInset: Float {
        get {
            return skeletonCellView.lineInset
        }

        set {
            skeletonCellView.lineInset = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class ListSkeletonContentView: UITableView, UITableViewDataSource {
    let randomizeDummyItem: Bool

    init(randomizeDummyItem: Bool) {
        self.randomizeDummyItem = randomizeDummyItem

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
            skeletonCell.lineInset =  randomizeDummyItem ? Float(arc4random() % 200) : 0
        }

        return cell!
    }

}

final class ListSkeletonView: UIView {

    let topBar: TopBar = {
        let bar = TopBar()
        let titleItem = ListSkeletonCellNameItemView()

        NSLayoutConstraint.activate([titleItem.widthAnchor.constraint(equalToConstant: 140),
                                     titleItem.heightAnchor.constraint(equalToConstant: 14)])

        bar.middleView = titleItem
        return bar
    }()

    let listContentView: ListSkeletonContentView
    var buttonRowView: UIStackView!

    init(_ account: Account, randomizeDummyItem: Bool) {
        let accountView = AccountViewFactory.viewFor(account: account, displayContext: .conversationListHeader) as BaseAccountView
        accountView.selected = false

        self.listContentView = ListSkeletonContentView(randomizeDummyItem: randomizeDummyItem)

        super.init(frame: CGRect.zero)

        buttonRowView = UIStackView(arrangedSubviews: disabledButtons(with: [.person, .archive]))
        buttonRowView.distribution = .equalCentering

        [topBar,
         listContentView, buttonRowView].forEach(addSubview)

        topBar.leftView = accountView.wrapInAvatarSizeContainer()

        createConstraints()
    }

    func disabledButtons(with iconTypes: [StyleKitIcon]) -> [IconButton] {
        return iconTypes.map { (iconType) in
            let button = IconButton()
            button.setIcon(iconType, size: .tiny, for: .normal)
            button.setIconColor(UIColor.init(white: 1.0, alpha: 0.32), for: .disabled)
            button.isEnabled = false
            return button
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createConstraints() {
        topBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeTopAnchor),
            topBar.leftAnchor.constraint(equalTo: leftAnchor),
            topBar.rightAnchor.constraint(equalTo: rightAnchor),
            topBar.bottomAnchor.constraint(equalTo: listContentView.topAnchor, constant: -10)])

        constrain(self,
                  buttonRowView, listContentView) { (containerView,
                    buttonRowView, listContentView) in

                    buttonRowView.left == containerView.left + 16
                    buttonRowView.right == containerView.right - 16
                    buttonRowView.bottom == containerView.bottom - UIScreen.safeArea.bottom
                    buttonRowView.height == 55

                    listContentView.left == containerView.left
                    listContentView.right == containerView.right
                    listContentView.bottom == buttonRowView.top
        }
    }

}

final class SkeletonViewController: UIViewController {

    let account: Account
    let backgroundImageView: UIImageView
    let blurEffectView: UIVisualEffectView
    let listView: ListSkeletonView
    let customSplitViewController: SplitViewController

    init(from: Account?,
         to: Account,
         randomizeDummyItem: Bool = true) {

        if let fromUnwrapped = from, to.imageData == nil, to.teamName == nil {
            account = fromUnwrapped
        }
        else {
            account = to
        }

        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.backgroundImageView = UIImageView()
        self.customSplitViewController = SplitViewController()
        self.listView = ListSkeletonView(account, randomizeDummyItem: randomizeDummyItem)

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
        customSplitViewController.setLeftViewControllerRevealed(true, animated: false)
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
            return .lightContent
        } else {
            return .compatibleDarkContent
        }
    }

}
