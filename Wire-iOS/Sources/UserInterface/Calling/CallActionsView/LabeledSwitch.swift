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

protocol LabeledSwitchDelegate: class {
    func switchPositionDidChange(to: LabeledSwitch.Position)
}

class LabeledSwitch: UIView {
    
    enum Position {
        case left
        case right
    }
    
    private let stackView: UIStackView = {
        let view = UIStackView(axis: .horizontal)
        view.distribution = .fillProportionally
        return view
    }()
    
    private let leftButton = UIButton()
    private let rightButton = UIButton()
    private var selectedPosition: Position
    
    weak var delegate: LabeledSwitchDelegate?

    init(leftText: String, rightText: String, position: Position) {
        self.selectedPosition = position
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        leftButton.setTitle(leftText, for: .normal)
        rightButton.setTitle(rightText, for: .normal)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = CallActionAppearance.dark(blurred: false).backgroundColorNormal
        addSubview(stackView)
        [leftButton, rightButton].forEach {
            stackView.addArrangedSubview($0)
            $0.titleLabel?.font = .smallMediumFont
            $0.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        }
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
    func buttonAction(_ sender: UIButton) {
        let newPosition: Position
        switch sender {
        case leftButton:
            newPosition = .left
        case rightButton:
            newPosition = .right
        }
        
        guard selectedPosition != newPosition else { return }
        leftButton.set(selected: sender == leftButton)
        rightButton.set(selected: sender == rightButton)
        delegate?.switchPositionDidChange(to: newPosition)
        selectedPosition = newPosition
    }
}

private extension UIButton {
    func set(selected: Bool) {
        backgroundColor = selected ? .white : .clear
        setTitleColor(selected ? .black : .white, for: .normal)
    }
}
