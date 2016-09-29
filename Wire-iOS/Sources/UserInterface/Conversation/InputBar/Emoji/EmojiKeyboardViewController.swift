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
    func emojiKeyboardViewControllerDeleteTapped(_ viewController: EmojiKeyboardViewController)
}


@objc class EmojiKeyboardViewController: UIViewController {
    
    weak var delegate: EmojiKeyboardViewControllerDelegate?
    
    var emojiDataSource: EmojiDataSource!
    let collectionView = EmojiCollectionView()
    let sectionViewController = EmojiSectionViewController(types: EmojiSectionType.all)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emojiDataSource = EmojiDataSource(provider: cellForEmoji)
        collectionView.dataSource = emojiDataSource
        collectionView.delegate = self
        sectionViewController.sectionDelegate = self
        setupViews()
        createConstraints()
    }
    
    func setupViews() {
        let colorScheme = ColorScheme()
        colorScheme.variant = .light
        view.backgroundColor = colorScheme.color(withName: ColorSchemeColorTextForeground)
        view.addSubview(collectionView)

        addChildViewController(sectionViewController)
        view.addSubview(sectionViewController.view)
        sectionViewController.didMove(toParentViewController: self)
    }
    
    func createConstraints() {
        constrain(view, collectionView, sectionViewController.view) { view, collectionView, sectionView in
            collectionView.top == view.top
            collectionView.leading == view.leading
            collectionView.trailing == view.trailing
            collectionView.bottom == sectionView.top
            sectionView.bottom == view.bottom
            sectionView.leading == view.leading
            sectionView.trailing == view.trailing
        }
    }
    
    func cellForEmoji(_ emoji: Emoji, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.zm_reuseIdentifier, for: indexPath) as! EmojiCollectionViewCell
        cell.titleLabel.text = emoji
        return cell
    }
    
}

extension EmojiKeyboardViewController: EmojiSectionViewControllerDelegate {

    func sectionViewController(_ viewController: EmojiSectionViewController, performAction action: EmojiSectionViewController.Action) {
        switch action {
        case .select(let type):
            guard let section = emojiDataSource.sectionIndex(for: type) else { return }
            let indexPath = IndexPath(item: 0, section: section)
            collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        case .delete:
            delegate?.emojiKeyboardViewControllerDeleteTapped(self)
        }
    }

}


extension EmojiKeyboardViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.emojiKeyboardViewController(self, didSelectEmoji: emojiDataSource[indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        sectionViewController.didSelectSection(emojiDataSource[indexPath.section].type)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let (first, last) = (section == 0, section == collectionView.numberOfSections)
        return UIEdgeInsets(top: 0, left: !first ? 12 : 0, bottom: 0, right: !last ? 12 : 0)
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
        titleLabel.font = .systemFont(ofSize: 28)
        titleLabel.adjustsFontSizeToFitWidth = true
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
        showsHorizontalScrollIndicator = false
        EmojiCollectionViewCell.register(in: self)
        setupLayout()
        contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = contentSize.height / 5
        layout.itemSize = CGSize(width: size, height: size)
    }
    
    func setupLayout() {
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


