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


@objc
enum ConversationListButtonType: UInt {
    case archive, startUI
}

@objc protocol ConversationListBottomBarControllerDelegate: class {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}

final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    let startUIButton  = IconButton()
    let archivedButton = IconButton()

    let separator = UIView()
    private let heightConstant: CGFloat = 56
    private let xInset: CGFloat = 16

    private var didLayout = false

    var showArchived: Bool = false {
        didSet {
            guard didLayout else { return }
            updateViews()
        }
    }

    private let showComposeButtons: Bool = false // Set this to show the compose buttons

    var showSeparator: Bool {
        set { separator.fadeAndHide(!newValue) }
        get { return !separator.isHidden }
    }

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.clear
        createViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func createViews() {
        separator.backgroundColor = UIColor.from(scheme: .separator, variant: .light)
        
        archivedButton.setIcon(.archive, size: .tiny, for: [])
        archivedButton.addTarget(self, action: #selector(archivedButtonTapped), for: .touchUpInside)
        archivedButton.accessibilityIdentifier = "bottomBarArchivedButton"
        archivedButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.archived_button.label".localized
        archivedButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.archived_button.hint".localized

        startUIButton.setIcon(.person, size: .tiny, for: .normal)
        startUIButton.addTarget(self, action: #selector(startUIButtonTapped), for: .touchUpInside)
        startUIButton.accessibilityIdentifier = "bottomBarPlusButton"
        startUIButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.contacts_button.label".localized
        startUIButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.contacts_button.hint".localized

        [archivedButton, startUIButton].forEach { button in
            button.setIconColor(UIColor.from(scheme: .textForeground, variant: .dark), for: .normal)
        }

        addSubviews()
        [separator, archivedButton].forEach{ $0.isHidden = true }

        if !showComposeButtons {
            createConstraints()
        }
    }

    private func addSubviews() {
        [archivedButton, startUIButton, separator].forEach(view.addSubview)
    }

    private func createConstraints() {
        constrain(view, separator) { view, separator in
            view.height == heightConstant ~ 750
            separator.height == .hairline
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == view.top
        }

        constrain(view, startUIButton, archivedButton) { view, startUIButton, archivedButton in
            startUIButton.centerY == view.centerY
            archivedButton.centerY == view.centerY
            archivedButton.trailing == view.trailing - xInset

            if showArchived {
                startUIButton.leading == view.leading + xInset
            } else {
                startUIButton.centerX == view.centerX
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViews()
        didLayout = true
    }

    func updateViews() {
        archivedButton.isHidden = !showArchived
        [archivedButton, startUIButton, separator].forEach { $0.removeFromSuperview() }
        
        addSubviews()
        createConstraints()
    }

    // MARK: - Target Action

    @objc private dynamic func archivedButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .archive)
    }

    @objc private dynamic func startUIButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .startUI)
    }
}

// MARK: - Helper

public extension UIView {
    func fadeAndHide(_ hide: Bool, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = UIView.AnimationOptions()) {
        if !hide {
            alpha = 0
            isHidden = false
        }

        let animations = { self.alpha = hide ? 0 : 1 }
        let completion: (Bool) -> Void = { _ in self.isHidden = hide }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(), animations: animations, completion: completion)
    }
}

