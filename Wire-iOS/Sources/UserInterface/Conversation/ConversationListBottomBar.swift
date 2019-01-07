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
    case archive, compose, camera, startUI
}

@objc protocol ConversationListBottomBarControllerDelegate: class {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}


@objcMembers final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    let startUIButton  = IconButton()
    let archivedButton = IconButton()
    let cameraButton   = IconButton()
    let composeButton  = IconButton()

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

    required init(delegate: ConversationListBottomBarControllerDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.view.backgroundColor = UIColor.clear
        createViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func createViews() {
        separator.backgroundColor = UIColor.from(scheme: .separator, variant: .light)
        
        archivedButton.setIcon(.archive, with: .tiny, for: [])
        archivedButton.addTarget(self, action: #selector(archivedButtonTapped), for: .touchUpInside)
        archivedButton.accessibilityIdentifier = "bottomBarArchivedButton"
        archivedButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.archived_button.label".localized
        archivedButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.archived_button.hint".localized

        startUIButton.setIcon(.person, with: .tiny, for: .normal)
        startUIButton.addTarget(self, action: #selector(startUIButtonTapped), for: .touchUpInside)
        startUIButton.accessibilityIdentifier = "bottomBarPlusButton"
        startUIButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.contacts_button.label".localized
        startUIButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.contacts_button.hint".localized

        composeButton.setIcon(.compose, with: .tiny, for: .normal)
        composeButton.addTarget(self, action: #selector(composeButtonTapped), for: .touchUpInside)
        composeButton.accessibilityIdentifier = "bottomBarComposeButton"
        composeButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.compose_button.label".localized
        composeButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.compose_button.hint".localized

        cameraButton.setIcon(.cameraLens, with: .tiny, for: .normal)
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        cameraButton.accessibilityIdentifier = "bottomBarCameraButton"
        cameraButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.camera_button.label".localized
        cameraButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.camera_button.hint".localized

        [archivedButton, startUIButton, composeButton, cameraButton].forEach { button in
            button.setIconColor(UIColor.from(scheme: .textForeground, variant: .dark), for: .normal)
        }

        addSubviews()
        [separator, archivedButton].forEach{ $0.isHidden = true }

        if !showComposeButtons {
            createConstraints()
        }
    }

    private func addSubviews() {
        if showComposeButtons {
            [cameraButton, composeButton, archivedButton, startUIButton, separator].forEach(view.addSubview)
        } else {
            [archivedButton, startUIButton, separator].forEach(view.addSubview)
        }
    }

    private func createConstraints() {
        constrain(view, separator) { view, separator in
            view.height == heightConstant ~ 750
            separator.height == .hairline
            separator.leading == view.leading
            separator.trailing == view.trailing
            separator.top == view.top
        }

        if showComposeButtons {
            createConstraintsWithComposeButtons()
        } else {
            createConstraintsWithoutComposeButtons()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViews()
        didLayout = true
    }

    private func createConstraintsWithoutComposeButtons() {
        constrain(view, cameraButton, startUIButton, archivedButton, composeButton) { view, cameraButton, startUIButton, archivedButton, composeButton in
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

    private func createConstraintsWithComposeButtons() {
        let containerWidth = composeButton.frame.midX - cameraButton.frame.midX

        constrain(view, cameraButton, startUIButton, archivedButton, composeButton) { view, cameraButton, startUIButton, archivedButton, composeButton in
            startUIButton.centerY == view.centerY
            archivedButton.centerY == view.centerY

            cameraButton.centerY == view.centerY
            composeButton.centerY == view.centerY
            cameraButton.leading == view.leading + xInset
            composeButton.trailing == view.trailing - xInset

            if showArchived {
                let spacingX = containerWidth / 3
                startUIButton.centerX == cameraButton.centerX + spacingX
                archivedButton.centerX == startUIButton.centerX + spacingX
            } else {
                startUIButton.center == view.center
            }
        }
    }

    func updateViews() {
        archivedButton.isHidden = !showArchived

        if showComposeButtons {
            [cameraButton, composeButton, archivedButton, startUIButton, separator].forEach { $0.removeFromSuperview() }
        } else {
            [archivedButton, startUIButton, separator].forEach { $0.removeFromSuperview() }
        }
        
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

    @objc private dynamic func cameraButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .camera)
    }

    @objc private dynamic func composeButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .compose)
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

