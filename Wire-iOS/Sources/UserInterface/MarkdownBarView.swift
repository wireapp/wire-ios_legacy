//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Down
import WireCommonComponents

protocol MarkdownBarViewDelegate: AnyObject {
    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton)
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton)
}

final class MarkdownBarView: UIView {

    weak var delegate: MarkdownBarViewDelegate?

    private let stackView =  UIStackView()

    private let enabledStateIconColor = SemanticColors.Button.textInputBarItemEnabled
    private let highlightedStateIconColor = SemanticColors.Button.textInputBarItemHighlighted

    private let enabledStateBackgroundColor = SemanticColors.Button.backgroundInputBarItemEnabled
    private let highlightedStateBackgroundColor = SemanticColors.Button.backgroundInputBarItemHighlighted

    private let enabledStateBorderColor = SemanticColors.Button.borderInputBarItemEnabled
    private let highlightedStateBorderColor = SemanticColors.Button.borderInputBarItemHighlighted

    let headerButton         = PopUpIconButton()
    let boldButton           = IconButton()
    let italicButton         = IconButton()
    let numberListButton     = IconButton()
    let bulletListButton     = IconButton()
    let codeButton           = IconButton()

    let buttons: [IconButton]

    private var buttonMargin: CGFloat {
        return conversationHorizontalMargins.left / 2 - StyleKitIcon.Size.tiny.rawValue / 2
    }

    required init() {
        buttons = [headerButton, boldButton, italicButton, numberListButton, bulletListButton, codeButton]
        super.init(frame: CGRect.zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    private func setupViews() {

        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: buttonMargin, bottom: 0, right: buttonMargin)
        stackView.isLayoutMarginsRelativeArrangement = true

        headerButton.setIcon(.markdownH1, size: .tiny, for: .normal)
        boldButton.setIcon(.markdownBold, size: .tiny, for: .normal)
        italicButton.setIcon(.markdownItalic, size: .tiny, for: .normal)
        numberListButton.setIcon(.markdownNumberList, size: .tiny, for: .normal)
        bulletListButton.setIcon(.markdownBulletList, size: .tiny, for: .normal)
        codeButton.setIcon(.markdownCode, size: .tiny, for: .normal)

        for button in buttons {
            // We apply the corner radius only for the first and the last button
            if button == buttons.first {
                button.layer.cornerRadius = 12
                button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            }

            if button == buttons.last {
                button.layer.cornerRadius = 12
                button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            }

            button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 20, bottom: 9, right: 20)
            button.layer.borderWidth = 1
            button.clipsToBounds = true

            button.setIconColor(enabledStateIconColor, for: .normal)
            button.setBorderColor(enabledStateBorderColor, for: .normal)
            button.setBackgroundImageColor(enabledStateBackgroundColor, for: .normal)

            button.setIconColor(highlightedStateIconColor, for: .highlighted)
            button.setBorderColor(highlightedStateBorderColor, for: .highlighted)
            button.setBackgroundImageColor(highlightedStateBackgroundColor, for: .highlighted)

            button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          stackView.topAnchor.constraint(equalTo: topAnchor),
          stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
          stackView.leftAnchor.constraint(equalTo: leftAnchor),
          stackView.rightAnchor.constraint(equalTo: rightAnchor)
        ])

        headerButton.itemIcons = [.markdownH1, .markdownH2, .markdownH3]
        headerButton.delegate = self
        headerButton.setupView()
    }

    @objc func textViewDidChangeActiveMarkdown(note: Notification) {
        guard let textView = note.object as? MarkdownTextView else { return }
        updateIcons(for: textView.activeMarkdown)
    }

    // MARK: Actions

    @objc private func buttonTapped(sender: IconButton) {

        guard let markdown = markdown(for: sender) else { return }

        if sender.iconColor(for: .normal) != enabledStateIconColor {
            delegate?.markdownBarView(self, didDeselectMarkdown: markdown, with: sender)
        } else {
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: sender)
        }
    }

    // MARK: - Conversions

    fileprivate func markdown(for button: IconButton) -> Markdown? {
        switch button {
        case headerButton:      return headerButton.icon(for: .normal)?.headerMarkdown ?? .h1
        case boldButton:        return .bold
        case italicButton:      return .italic
        case codeButton:        return .code
        case numberListButton:  return .oList
        case bulletListButton:  return .uList
        default:                return nil
        }
    }

    func updateIcons(for markdown: Markdown) {
        // change header icon if necessary
        if let headerIcon = markdown.headerValue?.headerIcon {
            headerButton.setIcon(headerIcon, size: .tiny, for: .normal)
        }

        for button in buttons {
            guard let buttonMarkdown = self.markdown(for: button) else { continue }
            let iconColor = markdown.contains(buttonMarkdown) ? highlightedStateIconColor : enabledStateIconColor
            let backgroundColor = markdown.contains(buttonMarkdown) ? highlightedStateBackgroundColor : enabledStateBackgroundColor
            let borderColor = markdown.contains(buttonMarkdown) ? highlightedStateBorderColor : enabledStateBorderColor
            button.setIconColor(iconColor, for: .normal)
            button.setBorderColor(borderColor, for: .normal)
            button.setBackgroundImageColor(backgroundColor, for: .normal)
        }
    }

    @objc func resetIcons() {
        buttons.forEach {
            $0.setIconColor(enabledStateIconColor, for: .normal)
            $0.setBorderColor(enabledStateBorderColor, for: .normal)
            $0.setBackgroundImageColor(enabledStateBackgroundColor, for: .normal)
        }
    }
}

extension MarkdownBarView: PopUpIconButtonDelegate {

    func popUpIconButton(_ button: PopUpIconButton, didSelectIcon icon: StyleKitIcon) {

        if button === headerButton {
            let markdown = icon.headerMarkdown ?? .h1
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: button)
        }
    }
}

private extension StyleKitIcon {
    var headerMarkdown: Markdown? {
        switch self {
        case .markdownH1: return .h1
        case .markdownH2: return .h2
        case .markdownH3: return .h3
        default:          return nil
        }
    }
}

private extension Markdown {
    var headerIcon: StyleKitIcon? {
        switch self {
        case .h1: return .markdownH1
        case .h2: return .markdownH2
        case .h3: return .markdownH3
        default:  return nil
        }
    }
}
