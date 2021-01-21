//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UIKit

protocol RoundedSegmentedViewDelegate: class {
    func roundedSegmentedView(_ view: RoundedSegmentedView, didSelectSegmentAtIndex index: Int)
}

class RoundedSegmentedView: UIControl {
    
    private let stackView: UIStackView = {
        let view = UIStackView(axis: .horizontal)
        view.distribution = .fillProportionally
        return view
    }()
        
    private var buttons = [UIButton]()
    private var selectedButton: UIButton?

    weak var delegate: RoundedSegmentedViewDelegate?

    init(items: [String]) {
        super.init(frame: .zero)
        setupViews(with: items)
        setupConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(_ selected: Bool, forItemAt index: Int) {
        guard selected else {
            return buttons[index].set(selected: false)
        }
        buttons.forEach {
            $0.set(selected: buttons.firstIndex(of: $0) == index)
        }
    }
    
    private func setupViews(with items: [String]) {
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .whiteAlpha16
        addSubview(stackView)
        items.forEach(addNewButton(withTitle:))
    }
    
    private func addNewButton(withTitle title: String) {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .smallMediumFont
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        buttons.append(button)
    }
    
    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    @objc
    private func buttonAction(_ sender: UIButton) {
        guard
            sender != selectedButton,
            let index = buttons.firstIndex(of: sender)
        else { return }
        
        selectedButton = sender
        setSelected(true, forItemAt: index)
        delegate?.roundedSegmentedView(self, didSelectSegmentAtIndex: index)
    }
}

private extension UIButton {
    func set(selected: Bool) {
        backgroundColor = selected ? .white : .clear
        setTitleColor(selected ? .black : .white, for: .normal)
    }
}
