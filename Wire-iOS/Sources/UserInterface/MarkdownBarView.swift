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

public protocol MarkdownBarViewDelegate: class {
    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton)
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton)
}


public final class MarkdownBarView: UIView {
    
    weak var delegate: MarkdownBarViewDelegate?
    
    private let stackView =  UIStackView()
    private let buttonMargin = WAZUIMagic.cgFloat(forIdentifier: "content.left_margin") / 2 - UIImage.size(for: .tiny) / 2
    private let accentColor = ColorScheme.default().accentColor
    private let normalColor = ColorScheme.default().color(withName: ColorSchemeColorIconNormal)
    
    public let headerButton         = PopUpIconButton()
    public let boldButton           = IconButton()
    public let italicButton         = IconButton()
    public let numberListButton     = IconButton()
    public let bulletListButton     = IconButton()
    public let codeButton           = IconButton()
    
    public let buttons: [IconButton]
    public var activeModes = [Markdown]()
    
    required public init() {
        buttons = [headerButton, boldButton, italicButton, numberListButton, bulletListButton, codeButton]
        super.init(frame: CGRect.zero)
        setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 56)
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
            let color = ColorScheme.default().color(withName: ColorSchemeColorIconNormal)
            button.setIconColor(color, for: .normal)
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
    
    func textViewDidChangeActiveMarkdown(note: Notification) {
        guard let textView = note.object as? MarkdownTextView else { return }
        updateIcons(forMarkdown: textView.activeMarkdown)
    }
    // MARK: Actions
    
    @objc private func buttonTapped(sender: IconButton) {
        
        let markdown: Markdown
        
        switch sender {
        case headerButton:
            switch headerButton.iconType(for: .normal) {
            // TODO: differentiate
            case .markdownH1:       markdown = .header
            case .markdownH2:       markdown = .header
            case .markdownH3:       markdown = .header
            default:                return
            }
        case boldButton:            markdown = .bold
        case italicButton:          markdown = .italic
        // TODO: differentiate
        case numberListButton:      markdown = .list
        case bulletListButton:      markdown = .list
        case codeButton:            markdown = .code
        default:                    return
        }
        
        if sender.iconColor(for: .normal) != normalColor {
            sender.setIconColor(normalColor, for: .normal)
            delegate?.markdownBarView(self, didDeselectMarkdown: markdown, with: sender)
        } else {
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: sender)
        }
    }
    
    // MARK: - Conversions
    
    private func buttonFor(_ markdown: Markdown) -> IconButton? {
        switch markdown {
        case .header:                       return headerButton
        case .bold:                         return boldButton
        case .italic:                       return italicButton
        case .code:                         return codeButton
        default:                            return nil
        }
    }
    
    fileprivate func markdown(for button: IconButton) -> Markdown? {
        switch button {
        case headerButton:                  return .header
        case boldButton:                    return .bold
        case italicButton:                  return .italic
        case codeButton:                    return .code
        default:                            return nil
        }
    }
    
    public func updateIcons(forMarkdown markdown: Markdown) {
        
        for button in buttons {
            guard let buttonMarkdown = self.markdown(for: button) else { continue }
            
            // current button not part of active markdown
            if markdown.isDisjoint(with: buttonMarkdown) {
                button.setIconColor(normalColor, for: .normal)
//                button.isEnabled = markdown.union(buttonMarkdown).isValid
            }
            else {
                button.setIconColor(accentColor, for: .normal)
            }
            
            // FIXME: disable unsupported buttons for now
            if buttonMarkdown == .none {
                button.isEnabled = false
            }
        }
    }
    
    @objc public func resetIcons() {
        buttons.forEach { $0.setIconColor(normalColor, for: .normal) }
    }
}

extension MarkdownBarView: PopUpIconButtonDelegate {
    
    func popUpIconButton(_ button: PopUpIconButton, didSelectIcon icon: ZetaIconType) {
        
        if button === headerButton {
            // TODO: differentiate header levels
            delegate?.markdownBarView(self, didSelectMarkdown: .header, with: button)
        }
    }
}
