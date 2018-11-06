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
import Cartography
import Down

protocol MarkdownBarViewDelegate: class {
    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton)
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton)
}


public final class MarkdownBarView: UIView {
    
    weak var delegate: MarkdownBarViewDelegate?
    
    private let stackView =  UIStackView()
    private let accentColor: UIColor = UIColor.accent()
    private let normalColor = UIColor.from(scheme: .iconNormal)
    
    public let headerButton         = PopUpIconButton()
    public let boldButton           = IconButton()
    public let italicButton         = IconButton()
    public let numberListButton     = IconButton()
    public let bulletListButton     = IconButton()
    public let codeButton           = IconButton()
    
    public let buttons: [IconButton]
    public var activeModes = [Markdown]()

    private var buttonMargin: CGFloat {
        return UIView.conversationLayoutMargins.left / 2 - UIImage.size(for: .tiny) / 2
    }
    
    required public init() {
        buttons = [headerButton, boldButton, italicButton, numberListButton, bulletListButton, codeButton]
        super.init(frame: CGRect.zero)
        setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
    
    private func setupViews() {
        
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: buttonMargin, bottom: 0, right: buttonMargin)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        
        headerButton.setIcon(.markdownH1, with: .tiny, for: .normal)
        boldButton.setIcon(.markdownBold, with: .tiny, for: .normal)
        italicButton.setIcon(.markdownItalic, with: .tiny, for: .normal)
        numberListButton.setIcon(.markdownNumberList, with: .tiny, for: .normal)
        bulletListButton.setIcon(.markdownBulletList, with: .tiny, for: .normal)
        codeButton.setIcon(.markdownCode, with: .tiny, for: .normal)
        
        for button in buttons {
            button.setIconColor(normalColor, for: .normal)
            button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        addSubview(stackView)
        
        constrain(self, stackView) { view, stackView in
            stackView.edges == view.edges
        }
        
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
        
        if sender.iconColor(for: .normal) != normalColor {
            delegate?.markdownBarView(self, didDeselectMarkdown: markdown, with: sender)
        } else {
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: sender)
        }
    }
    
    // MARK: - Conversions
        
    fileprivate func markdown(for button: IconButton) -> Markdown? {
        switch button {
        case headerButton:      return headerButton.iconType(for: .normal).headerMarkdown ?? .h1
        case boldButton:        return .bold
        case italicButton:      return .italic
        case codeButton:        return .code
        case numberListButton:  return .oList
        case bulletListButton:  return .uList
        default:                return nil
        }
    }
    
    public func updateIcons(for markdown: Markdown) {
        // change header icon if necessary
        if let headerIcon = markdown.headerValue?.headerIcon {
            headerButton.setIcon(headerIcon, with: .tiny, for: .normal)
        }
        
        for button in buttons {
            guard let buttonMarkdown = self.markdown(for: button) else { continue }
            let color = markdown.contains(buttonMarkdown) ? accentColor : normalColor
            button.setIconColor(color, for: .normal)
        }
    }
    
    @objc public func resetIcons() {
        buttons.forEach { $0.setIconColor(normalColor, for: .normal) }
    }
}

extension MarkdownBarView: PopUpIconButtonDelegate {
    
    func popUpIconButton(_ button: PopUpIconButton, didSelectIcon icon: ZetaIconType) {
        
        if button === headerButton {
            let markdown = icon.headerMarkdown ?? .h1
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: button)
        }
    }
}

private extension ZetaIconType {
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
    var headerIcon: ZetaIconType? {
        switch self {
        case .h1: return .markdownH1
        case .h2: return .markdownH2
        case .h3: return .markdownH3
        default:  return nil
        }
    }
}
