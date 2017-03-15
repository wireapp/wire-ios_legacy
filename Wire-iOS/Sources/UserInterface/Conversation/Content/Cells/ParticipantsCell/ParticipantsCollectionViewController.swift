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


import Cartography


final class ParticipantsUserCell: UICollectionViewCell {

    private let imageView = UserImageView()
    private let dimmedAlpha: CGFloat = 0.5
    private let highlightAlphaDifference: CGFloat = 0.3

    var dimmed: Bool = false {
        didSet {
            imageView.alpha = dimmed ? dimmedAlpha : 1
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        constrain(self, imageView) { view, image in
            image.edges == view.edges
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var user: ZMUser? {
        didSet {
            imageView.user = user
        }
    }

    override var isHighlighted: Bool {
        didSet {
            switch (dimmed, isHighlighted) {
            case (true, true): imageView.alpha = dimmedAlpha - highlightAlphaDifference
            case (true, false): imageView.alpha = dimmedAlpha
            case (false, true): imageView.alpha = 1 - highlightAlphaDifference
            case (false, false): imageView.alpha = 1
            }
        }
    }

}


final class ParticipantsCollectionViewController<Cell: UICollectionViewCell>: UICollectionViewController {

    private var heightConstraint: NSLayoutConstraint?

    typealias SelectAction = (ZMUser, UIView) -> Void
    typealias ConfigureCell = (ZMUser, Cell) -> Void

    var users: [ZMUser] = [] {
        didSet {
            collectionView?.reloadData()
            updateCollectionViewHeight()
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    var configureCell: ConfigureCell?
    var selectAction: SelectAction?

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6
        layout.itemSize = CGSize(width: 24, height: 24)
        super.init(collectionViewLayout: layout)
        Cell.register(in: collectionView!)
        collectionView?.isScrollEnabled = false
        view.backgroundColor = .clear
        collectionView?.backgroundColor = .clear

        constrain(view) { view in
            heightConstraint = view.height == collectionView?.contentSize.height ?? layout.itemSize.height
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeight()
    }

    private func updateCollectionViewHeight() {
        heightConstraint?.constant = collectionView?.contentSize.height ?? 25
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.zm_reuseIdentifier, for: indexPath) as! Cell
        configureCell?(users[indexPath.item], cell)
        return cell
    }

    override func collectionView(_ cView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cView.deselectItem(at: indexPath, animated: true)
        selectAction?(users[indexPath.item], collectionView(cView, cellForItemAt: indexPath))
    }

}
