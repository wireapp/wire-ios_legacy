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

enum ImageToolbarConfiguration {
    case cell
    case compactCell
    case preview
}

final class ImageToolbarView: UIView {

    let buttonContainer = UIView()
    let sketchButton = IconButton()
    let emojiButton = IconButton()
    let textButton = IconButton()
    let expandButton = IconButton()
    var buttons: [IconButton] = []

    var configuration: ImageToolbarConfiguration {
        didSet {
            guard oldValue != configuration else { return }

            updateButtonConfiguration()
        }
    }

    var showsSketchButton = true {
        didSet {
            guard oldValue != showsSketchButton else { return }
            updateButtonConfiguration()
        }
    }

    var imageIsEphemeral = false {
        didSet {
            guard oldValue != imageIsEphemeral else { return }
            updateButtonConfiguration()
        }
    }

    var isPlacedOnImage: Bool = false {
        didSet {
            backgroundColor = isPlacedOnImage ? UIColor(white: 0, alpha: 0.40) : UIColor.clear
            updateButtonStyle()
        }
    }

    private func updateButtonStyle() {
        let normalColor: UIColor = isPlacedOnImage ? .from(scheme: .iconNormal, variant: .dark) : .from(scheme: .iconNormal)
        let highlightedColor: UIColor = isPlacedOnImage ? .from(scheme: .iconHighlighted, variant: .dark) : .from(scheme: .iconHighlighted)
        let selectedColor: UIColor = isPlacedOnImage ? .accentDarken : .accent()

        [sketchButton, emojiButton, textButton, expandButton].forEach {
            $0.setIconColor(normalColor, for: .normal)
            $0.setIconColor(highlightedColor, for: .highlighted)
            $0.setIconColor(selectedColor, for: .selected)
        }
    }

    init(withConfiguraton configuration: ImageToolbarConfiguration) {
        self.configuration = configuration

        super.init(frame: CGRect.zero)

        updateButtonStyle()

        addSubview(buttonContainer)

        constrain(self, buttonContainer) { container, buttonContainer in
            buttonContainer.centerX == container.centerX
            buttonContainer.top == container.top
            buttonContainer.bottom == container.bottom
            buttonContainer.left >= container.left
            buttonContainer.right <= container.right
        }

        setupButtons()
        updateButtonConfiguration()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateButtonConfiguration() {
        buttons.forEach({ $0.removeFromSuperview() })
        var newButtons = showsSketchButton ? [sketchButton] : []

        switch configuration {
        case .cell where imageIsEphemeral, .compactCell where imageIsEphemeral:
            // ephemeral images should only expand
            newButtons = [expandButton]
        case .cell:
            newButtons.append(contentsOf: [emojiButton, expandButton])
        case .compactCell:
            newButtons.append(expandButton)
        case .preview:
            newButtons.append(emojiButton)
        }

        buttons = newButtons
        buttons.forEach(buttonContainer.addSubview)
        createButtonConstraints()
    }

    func createButtonConstraints() {
        let spacing: CGFloat = 16

        if let firstButton = buttons.first {
            constrain(buttonContainer, firstButton) { container, firstButton in
                firstButton.left == container.left + spacing
            }
        }

        if let lastButton = buttons.last {
            constrain(buttonContainer, lastButton) { container, lastButton in
                lastButton.right == container.right - spacing
            }
        }

        for button in buttons {
            constrain(buttonContainer, button) { container, button in
                button.width == 16
                button.height == 16
                button.centerY == container.centerY
            }
        }

        for i in 1..<buttons.count {
            let previousButton = buttons[i-1]
            let button = buttons[i]

            constrain(self, button, previousButton) { _, button, previousButton in
                button.left == previousButton.right + spacing * 2
            }
        }
    }

    func setupButtons() {
        let hitAreaPadding = CGSize(width: 16, height: 16)

        sketchButton.setIcon(.brush, size: .tiny, for: .normal)
        sketchButton.hitAreaPadding = hitAreaPadding
        sketchButton.accessibilityIdentifier = "sketchButton"

        emojiButton.setIcon(.emoji, size: .tiny, for: .normal)
        emojiButton.hitAreaPadding = hitAreaPadding
        emojiButton.accessibilityIdentifier = "emojiButton"

        textButton.setIcon(.pencil, size: .tiny, for: .normal)
        textButton.hitAreaPadding = hitAreaPadding
        textButton.accessibilityIdentifier = "textButton"

        expandButton.setIcon(.fullScreen, size: .tiny, for: .normal)
        expandButton.hitAreaPadding = hitAreaPadding
        expandButton.accessibilityIdentifier = "expandButton"
    }
}
