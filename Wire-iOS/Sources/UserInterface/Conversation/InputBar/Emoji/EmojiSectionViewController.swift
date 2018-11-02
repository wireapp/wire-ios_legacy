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


protocol EmojiSectionViewControllerDelegate: class {
    func sectionViewController(_ viewController: EmojiSectionViewController, didSelect: EmojiSectionType, scrolling: Bool)
}


class EmojiSectionViewController: UIViewController {

    private var typesByButton = [IconButton: EmojiSectionType]()
    private var sectionButtons = [IconButton]()
    private let iconSize = UIImage.size(for: .tiny)
    private var ignoreSelectionUpdates = false

    private var selectedType: EmojiSectionType? {
        willSet(value) {
            guard let type = value else { return }
            typesByButton.forEach { button, sectionType in
                button.isSelected = type == sectionType
            }
        }
    }
    
    weak var sectionDelegate: EmojiSectionViewControllerDelegate? = nil
    
    init(types: [EmojiSectionType]) {
        super.init(nibName: nil, bundle: nil)
        createButtons(types)

        setupViews()
        createConstraints()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
        selectedType = typesByButton.values.first
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createButtons(_ types: [EmojiSectionType]) {
        sectionButtons = types.map(createSectionButton)
        zip(types, sectionButtons).forEach { (type, button) in
            typesByButton[button] = type
        }
    }
    
    private func setupViews() {
        sectionButtons.forEach(view.addSubview)
    }
    
    private func createSectionButton(for type: EmojiSectionType) -> IconButton {

        let button: IconButton = {
            let button = IconButton(style: .default)
            button.setIconColor(UIColor.from(scheme: .textDimmed, variant: .dark), for: .normal)
            button.setIconColor(.from(scheme: .textForeground, variant: .dark), for: .selected)
            button.setIconColor(.from(scheme: .iconHighlighted, variant: .dark), for: .highlighted)
            button.setBackgroundImageColor(.clear, for: .selected)
            button.setBorderColor(.clear, for: .normal)
            button.circular = false
            button.borderWidth = 0

            button.setIcon(type.icon, with: .tiny, for: .normal)

            return button
        }()

        button.addTarget(self, action: #selector(didTappButton), for: .touchUpInside)
        return button
    }
    
    func didSelectSection(_ type: EmojiSectionType) {
        guard let selected = selectedType, type != selected, !ignoreSelectionUpdates else { return }
        selectedType = type
    }
    
    @objc private func didTappButton(_ sender: IconButton) {
        guard let type = typesByButton[sender] else { return }
        sectionDelegate?.sectionViewController(self, didSelect: type, scrolling: false)
    }

    @objc private func didPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .possible: break
        case .began:
            ignoreSelectionUpdates = true
            fallthrough
        case .changed:
            let location = recognizer.location(in: view)
            guard let button = sectionButtons.filter ({ $0.frame.contains(location) }).first else { return }
            guard let type = typesByButton[button] else { return }
            sectionDelegate?.sectionViewController(self, didSelect: type, scrolling: true)
            selectedType = type
        case .ended, .failed, .cancelled:
            ignoreSelectionUpdates = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sectionButtons.forEach {
            $0.removeFromSuperview()
            view.addSubview($0)
        }

        createConstraints()
        sectionButtons.forEach {
            $0.hitAreaPadding = CGSize(width: 5, height: view.bounds.height / 2)
        }
    }
    
    private func createConstraints() {
        
        let inset: CGFloat = 16
        let count = CGFloat(sectionButtons.count)
        let fullSpacing = (view.bounds.width - 2 * inset) - iconSize
        let padding = fullSpacing / (count - 1)

        constrain(view, sectionButtons.first!) { view, firstButton in
            firstButton.leading == view.leading + inset
            view.height == iconSize + inset
        }
        
        sectionButtons.enumerated().dropFirst().forEach { idx, button in
            constrain(button, sectionButtons[idx - 1], view) { button, previous, view in
                button.centerX == previous.centerX + padding
            }
        }
        
        sectionButtons.forEach {
            constrain($0, view) { button, view in
                button.top == view.top
            }
        }
    }
    
}
