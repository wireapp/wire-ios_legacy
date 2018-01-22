//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public class RadioButtonsView<T: UIButton>: UIView {
    public let buttons: [T]
    public var selectedIndex: Int? = nil {
        didSet {
            buttons.forEach { $0.isSelected = false }
            
            guard let index = selectedIndex else {
                return
            }
            buttons[index].isSelected = true
        }
    }
    
    private let stackView = UIStackView()
    
    public init(buttons: [T]) {
        self.buttons = buttons
        super.init(frame: .zero)
        
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.alignment = . fill
        addSubview(stackView)
        
        constrain(self, stackView) { selfView, stackView in
            stackView.edges == selfView.edges
        }
        
        buttons.forEach(stackView.addArrangedSubview)
        buttons.forEach { $0.addCallback(for: .touchUpInside) { [weak self] selectedButton in
                self?.selectedIndex = buttons.index(of: selectedButton)!
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
