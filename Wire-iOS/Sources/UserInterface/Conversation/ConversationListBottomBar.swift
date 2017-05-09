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
    case archive, compose, camera, plus
}

@objc protocol ConversationListBottomBarControllerDelegate: class {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}


@objc final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    let plusButton     = IconButton()
    let archivedButton = IconButton()
    let cameraButton   = IconButton()
    let composeButton  = IconButton()

    let separator = UIView()
    private let heightConstant: CGFloat = 56

    private var didLayout = false

    var showArchived: Bool = false {
        didSet {
            guard didLayout else { return }
            updateViews()
        }
    }

    lazy private var showComposeButtons: Bool = {
        let debugHideComposeButtonsOverride = false // Set this to not show the compose buttons when debugging
        return DeveloperMenuState.developerMenuEnabled() && !debugHideComposeButtonsOverride
    }()

    var showSeparator: Bool {
        set { separator.fadeAndHide(!newValue) }
        get { return !separator.isHidden }
    }

    required init(delegate: ConversationListBottomBarControllerDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        createViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func createViews() {
        archivedButton.setIcon(.archive, with: .tiny, for: UIControlState())
        archivedButton.addTarget(self, action: #selector(archivedButtonTapped), for: .touchUpInside)
        archivedButton.accessibilityIdentifier = "bottomBarArchivedButton"

        plusButton.setIcon(.plus, with: .tiny, for: .normal)
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        plusButton.accessibilityIdentifier = "bottomBarPlusButton"

        composeButton.setIcon(.compose, with: .tiny, for: .normal)
        composeButton.addTarget(self, action: #selector(composeButtonTapped), for: .touchUpInside)
        composeButton.accessibilityIdentifier = "bottomBarComposeButton"

        cameraButton.setIcon(.cameraLens, with: .tiny, for: .normal)
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        cameraButton.accessibilityIdentifier = "bottomBarCameraButton"

        view.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        addSubviews()
        [separator, archivedButton].forEach{ $0.isHidden = true }

        if !showComposeButtons {
            createConstraints()
        }
    }

    private func addSubviews() {
        if showComposeButtons {
            [cameraButton, composeButton, archivedButton, plusButton, separator].forEach(view.addSubview)
        } else {
            [archivedButton, plusButton, separator].forEach(view.addSubview)
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
        constrain(view, cameraButton, plusButton, archivedButton, composeButton) { view, cameraButton, plusButton, archivedButton, composeButton in
            plusButton.centerY == view.centerY
            archivedButton.centerY == view.centerY
            plusButton.leading == view.leadingMargin
            archivedButton.trailing == view.trailingMargin
        }
    }

    private func createConstraintsWithComposeButtons() {
        let containerWidth = composeButton.frame.minX - cameraButton.frame.maxX

        constrain(view, cameraButton, plusButton, archivedButton, composeButton) { view, cameraButton, plusButton, archivedButton, composeButton in
            plusButton.centerY == view.centerY
            archivedButton.centerY == view.centerY

            cameraButton.centerY == view.centerY
            composeButton.centerY == view.centerY
            cameraButton.leading == view.leadingMargin
            composeButton.trailing == view.trailingMargin

            plusButton.width == heightConstant
            archivedButton.width == plusButton.width

            if showArchived {
                let spacingX = (containerWidth - (heightConstant * 2)) / 3
                plusButton.leading == cameraButton.trailing + spacingX
                archivedButton.leading == plusButton.trailing + spacingX
            } else {
                plusButton.center == view.center
            }
        }
    }

    func updateViews() {
        archivedButton.isHidden = !showArchived

        if showComposeButtons {
            [cameraButton, composeButton, archivedButton, plusButton, separator].forEach { $0.removeFromSuperview() }
            addSubviews()
            createConstraints()
        }
    }

    // MARK: - Target Action

    private dynamic func archivedButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .archive)
    }

    private dynamic func plusButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .plus)
    }

    private dynamic func cameraButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .camera)
    }

    private dynamic func composeButtonTapped(_ sender: IconButton) {
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

