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
import WireCommonComponents
import WireDataModel

final class ListSkeletonCellNameItemView: UIView {

    init() {
        super.init(frame: CGRect.zero)

        layer.cornerRadius = 4
        backgroundColor = .white
        alpha = 0.16
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ListSkeletonCellView: UIView {

    private let avatarView = UIView()
    private let lineView = ListSkeletonCellNameItemView()

    private lazy var lineConstraint: NSLayoutConstraint = lineView.rightAnchor.constraint(equalTo: rightAnchor)

    var lineInset: Float {
        get {
            let inset = lineConstraint.constant
            return -(Float)(inset)
        }

        set {
            lineConstraint.constant = -CGFloat(newValue + 16)
        }
    }

    init() {
        super.init(frame: .zero)

        avatarView.layer.cornerRadius = 14
        avatarView.backgroundColor = .white
        avatarView.alpha = 0.16

        [avatarView, lineView].forEach(addSubview)

        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [avatarView, lineView].prepareForLayout()

        NSLayoutConstraint.activate([
          avatarView.widthAnchor.constraint(equalToConstant: 28),
          avatarView.heightAnchor.constraint(equalToConstant: 28),
          avatarView.leftAnchor.constraint(equalTo: leftAnchor, constant: 18),
          avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
          avatarView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -17.5),

          lineView.heightAnchor.constraint(equalToConstant: 14),
          lineView.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 16),
          lineConstraint,
          lineView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        lineInset = 0
    }

}

final class ListSkeletonCell: UITableViewCell {

    static let estimatedHeight = 64.0

    private let skeletonCellView: ListSkeletonCellView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        skeletonCellView = ListSkeletonCellView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(skeletonCellView)
        skeletonCellView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          skeletonCellView.topAnchor.constraint(equalTo: contentView.topAnchor),
          skeletonCellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
          skeletonCellView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
          skeletonCellView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
    }

    var lineInset: Float {
        get {
            return skeletonCellView.lineInset
        }

        set {
            skeletonCellView.lineInset = newValue
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class ListSkeletonContentView: UITableView, UITableViewDataSource {
    let randomizeDummyItem: Bool

    init(randomizeDummyItem: Bool) {
        self.randomizeDummyItem = randomizeDummyItem

        super.init(frame: CGRect.zero, style: .plain)

        dataSource = self
        backgroundColor = .clear
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 28
        separatorColor = .clear
        isScrollEnabled = false
        allowsSelection = false

        register(ListSkeletonCell.self, forCellReuseIdentifier: "ListSkeletonCell")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(floor(Double(bounds.size.height) / ListSkeletonCell.estimatedHeight))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: "ListSkeletonCell")

        if let skeletonCell = cell as? ListSkeletonCell {
            skeletonCell.lineInset =  randomizeDummyItem ? Float.random(in: 0..<200) : 0
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
    lazy var buttonRowView: UIStackView = { UIStackView(arrangedSubviews: disabledButtons(with: [.person, .archive]))
    }()

    init(_ account: Account, randomizeDummyItem: Bool) {
        let accountView = AccountViewFactory.viewFor(account: account, displayContext: .conversationListHeader) as BaseAccountView
        accountView.selected = false

        listContentView = ListSkeletonContentView(randomizeDummyItem: randomizeDummyItem)

        super.init(frame: CGRect.zero)

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

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [topBar,
         buttonRowView,
         listContentView].prepareForLayout()

        NSLayoutConstraint.activate([
          topBar.topAnchor.constraint(equalTo: safeTopAnchor),
          topBar.leftAnchor.constraint(equalTo: leftAnchor),
          topBar.rightAnchor.constraint(equalTo: rightAnchor),
          topBar.bottomAnchor.constraint(equalTo: listContentView.topAnchor, constant: -10),

          buttonRowView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
          buttonRowView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
          buttonRowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UIScreen.safeArea.bottom),
          buttonRowView.heightAnchor.constraint(equalToConstant: 55),

          listContentView.leftAnchor.constraint(equalTo: leftAnchor),
          listContentView.rightAnchor.constraint(equalTo: rightAnchor),
          listContentView.bottomAnchor.constraint(equalTo: buttonRowView.topAnchor)
        ])
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
        } else {
            account = to
        }

        blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        backgroundImageView = UIImageView()
        customSplitViewController = SplitViewController()
        listView = ListSkeletonView(account, randomizeDummyItem: randomizeDummyItem)

        super.init(nibName: nil, bundle: nil)

        backgroundImageView.contentMode = .scaleAspectFill

        let factor = BackgroundViewController.backgroundScaleFactor
        backgroundImageView.transform = CGAffineTransform(scaleX: factor, y: factor)

        if let imageData = account.imageData, let image = BackgroundViewController.blurredAppBackground(with: imageData) {
            backgroundImageView.image = image
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        customSplitViewController.view.backgroundColor = .clear
        customSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(customSplitViewController)

        [backgroundImageView, blurEffectView, customSplitViewController.view].forEach(view.addSubview)

        createConstraints()

        customSplitViewController.didMove(toParent: self)

        let listViewController = UIViewController()
        listViewController.view = listView
        customSplitViewController.leftViewController = listViewController
        customSplitViewController.view.layoutIfNeeded()
        customSplitViewController.setLeftViewControllerRevealed(true, animated: false)
    }

    private func createConstraints() {
        guard let splitViewControllerView = customSplitViewController.view else { return }

        [blurEffectView, backgroundImageView, splitViewControllerView].prepareForLayout()

        NSLayoutConstraint.activate([
          blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
          blurEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          blurEffectView.leftAnchor.constraint(equalTo: view.leftAnchor),
          blurEffectView.rightAnchor.constraint(equalTo: view.rightAnchor),
          splitViewControllerView.topAnchor.constraint(equalTo: view.topAnchor),
          splitViewControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          splitViewControllerView.leftAnchor.constraint(equalTo: view.leftAnchor),
          splitViewControllerView.rightAnchor.constraint(equalTo: view.rightAnchor),
          backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
          backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -100),
          backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 100),
          backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if customSplitViewController.layoutSize == .compact {
            return .lightContent
        } else {
            return .compatibleDarkContent
        }
    }

}
