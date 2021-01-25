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

class RoundedSegmentedView: UIView {
    typealias ActionHandler = () -> Void

    private let stackView: UIStackView = {
        let view = UIStackView(axis: .horizontal)
        view.distribution = .fillProportionally
        return view
    }()
        
    private var buttons = [UIButton]()
    private var actionHandlers = [UIButton: ActionHandler]()

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(_ selected: Bool, forItemAt index: Int) {        
        for (i, button) in buttons.enumerated() {
            button.isSelected = i == index && selected
        }
    }
    
    private func setupViews() {
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .whiteAlpha16
        addSubview(stackView)
    }
    
    func addButton(withTitle title: String, actionHandler: @escaping ActionHandler) {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setBackgroundImage(.singlePixelImage(with: .clear), for: .normal)
        button.setBackgroundImage(.singlePixelImage(with: .white), for: .selected)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .smallMediumFont
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        buttons.append(button)
        actionHandlers[button] = actionHandler
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
            !sender.isSelected,
            let index = buttons.firstIndex(of: sender)
        else { return }
        
        setSelected(true, forItemAt: index)
        actionHandlers[sender]?()
    }
}
