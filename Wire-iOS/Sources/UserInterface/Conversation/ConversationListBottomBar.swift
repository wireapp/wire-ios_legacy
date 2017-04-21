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


@objc enum ConversationListButtonType: UInt {
    case archive, compose
}

@objc protocol ConversationListBottomBarControllerDelegate: class {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}


@objc final class ConversationListBottomBarController: UIViewController {
    
    weak var delegate: ConversationListBottomBarControllerDelegate?

    let plusButton     = IconButton()
    let archivedButton = IconButton()
    let plusButtonContainer = UIView()
    let archivedButtonContainer = UIView()
    let separator = UIView()
    let plusButtonTitle = "bottom_bar.plus_button.title".localized.uppercased()
    let heightConstant: CGFloat = 56

    var showArchived: Bool = false {
        didSet {
            updateArchivedVisibility()
        }
    }
    
    var showSeparator: Bool {
        set { separator.fadeAndHide(!newValue) }
        get { return !separator.isHidden }
    }
    
    required init(delegate: ConversationListBottomBarControllerDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        createViews()
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    fileprivate func createViews() {
        archivedButton.setIcon(.archive, with: .tiny, for: UIControlState())
        archivedButton.addTarget(self, action: #selector(ConversationListBottomBarController.archivedButtonTapped(_:)), for: .touchUpInside)
        archivedButton.accessibilityIdentifier = "bottomBarArchivedButton"

        plusButton.setIcon(.plus, with: .tiny, for: .normal)
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        plusButton.accessibilityIdentifier = "bottomBarPlusButton"
        plusButton.titleImageSpacing = 18
        plusButton.setTitle(plusButtonTitle, for: .normal)

        view.addSubview(plusButton)

        plusButtonContainer.addSubview(plusButton)
        archivedButtonContainer.addSubview(archivedButton)
        [separator, archivedButton].forEach { $0.isHidden = true }
        [plusButtonContainer, archivedButtonContainer, separator].forEach(view.addSubview)
    }
    
    fileprivate func createConstraints() {
        constrain(view, separator) { view, separator in
            view.height == heightConstant ~ 750
            
            separator.height == .hairline
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == view.top
        }
        
        constrain(view, plusButtonContainer, plusButton) { view, container, plusButton in
            container.leading == view.leading
            container.top == view.top
            container.bottom == view.bottom
            
            plusButton.leading == container.leading + 16
            plusButton.trailing == container.trailing - 18
            plusButton.centerY == container.centerY
        }
        
        constrain(view, archivedButtonContainer, archivedButton) { view, container, archivedButton in
            container.trailing == view.trailing
            container.top == view.top
            container.bottom == view.bottom
            
            archivedButton.trailing == container.trailing - 16
            archivedButton.leading == container.leading + 24
            archivedButton.centerY == container.centerY
        }
    }
    
    func updateArchivedVisibility() {
        archivedButton.isHidden = !showArchived
    }
    
    // MARK: - Target Action
    
    func archivedButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .archive)
    }

    func plusButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .compose)
    }
    
}

// MARK: - Helper

public extension UIView {
    func fadeAndHide(_ hide: Bool, duration: TimeInterval = 0.2, options: UIViewAnimationOptions = UIViewAnimationOptions()) {
        if !hide {
            alpha = 0
            isHidden = false
        }
        
        let animations = { self.alpha = hide ? 0 : 1 }
        let completion: (Bool) -> Void = { _ in self.isHidden = hide }
        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(), animations: animations, completion: completion)
    }
}

