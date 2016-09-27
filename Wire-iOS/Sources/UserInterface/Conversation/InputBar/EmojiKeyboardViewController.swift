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


import UIKit
import Cartography


protocol EmojiKeyboardViewControllerDelegate: class {
    func emojiKeyboardViewController(_ viewController: EmojiKeyboardViewController, didSelectEmoji emoji: String)
}

@objc class EmojiKeyboardViewController: UIViewController {
    
    weak var delegate: EmojiKeyboardViewControllerDelegate?
    
    let emojis = EmojiDataSource()
    let collectionView = EmojiCollectionView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        setupViews()
        createConstraints()
    }

    func setupViews() {
        let colorScheme = ColorScheme()
        colorScheme.variant = .light
        view.backgroundColor = colorScheme.color(withName: ColorSchemeColorTextForeground)
        view.addSubview(collectionView)
    }

    func createConstraints() {
        constrain(view, collectionView) { view, collectionView in
            collectionView.edges == view.edges
        }
    }

}

extension EmojiKeyboardViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0 else { return 0 }
        return emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.zm_reuseIdentifier, for: indexPath) as! EmojiCollectionViewCell
        cell.titleLabel.text = emojis[indexPath.item]
        return cell
    }
}

extension EmojiKeyboardViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.emojiKeyboardViewController(self, didSelectEmoji: emojis[indexPath.item])
    }

}


class EmojiCollectionViewCell: UICollectionViewCell {
    let titleLabel = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.6 : 1
            }
        }
    }
    
    func setupViews() {
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 40)
        addSubview(titleLabel)
    }
    
    func createConstraints() {
        constrain(self, titleLabel) { view, label in
            label.edges == view.edges
        }
    }
}


class EmojiCollectionView: UICollectionView {
    
    private let layout = UICollectionViewFlowLayout()
    
    init() {
        super.init(frame: .zero, collectionViewLayout: layout)
        backgroundColor = .clear
        indicatorStyle = .white
        contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        EmojiCollectionViewCell.register(in: self)
        setupLayout()
    }
    
    func setupLayout() {
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

