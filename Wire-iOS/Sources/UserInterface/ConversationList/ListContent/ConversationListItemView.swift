
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension Notification.Name {
    static let conversationListItemDidScroll = Notification.Name("ConversationListItemDidScroll")
}

final class ConversationListItemView: UIView {
    // Please use `updateForConversation:` to set conversation.
    var conversation: ZMConversation?
    var titleText: NSAttributedString? {
        didSet {
            titleField.attributedText = titleText
        }
    }

    var subtitleAttributedText: NSAttributedString? {
        didSet {
            subtitleField.attributedText = subtitleAttributedText
            subtitleField.accessibilityValue = subtitleAttributedText?.string
        }
    }
    
    let titleField: UILabel = UILabel()
    let avatarView: ConversationAvatarView = ConversationAvatarView()
    lazy var rightAccessory: ConversationListAccessoryView = {
        return ConversationListAccessoryView(mediaPlaybackManager: AppDelegate.shared.mediaPlaybackManager!)
    }()
    
    var selected = false {
        didSet {
            backgroundColor = selected ? UIColor(white: 0, alpha: 0.08) : .clear
        }
    }
    
    var visualDrawerOffset: CGFloat = 0 {
        didSet {
                setVisualDrawerOffset(visualDrawerOffset, notify: true)
        }
    }
    
    let labelsStack: UIStackView = UIStackView()
    let contentStack: UIStackView = UIStackView()
    private let subtitleField: UILabel = UILabel()
    let lineView: UIView = UIView()

    init() {
        super.init(frame: .zero)
        setupConversationListItemView()
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        addMediaPlaybackManagerPlayerStateObserver()
        
        setupStyle()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConversationListItemView() {
        setupContentStack()
        setupLabelsStack()
        setupTitleField()
        setupSubtitleField()
        
        configureFont()
        
        rightAccessory.accessibilityIdentifier = "status"
        
        contentStack.addArrangedSubview(avatarView)
        contentStack.addArrangedSubview(labelsStack)
        contentStack.addArrangedSubview(rightAccessory)
        
        lineView.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        addSubview(lineView)
        
        rightAccessory.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        titleField.setContentCompressionResistancePriority(.required, for: .vertical)
        titleField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleField.setContentHuggingPriority(.required, for: .vertical)
        titleField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        subtitleField.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleField.setContentHuggingPriority(.required, for: .vertical)
        subtitleField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        createConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(otherConversationListItemDidScroll(_:)), name: .conversationListItemDidScroll, object: nil)
    }

    private func setupLabelsStack() {
        labelsStack.axis = NSLayoutConstraint.Axis.vertical
        labelsStack.alignment = UIStackView.Alignment.leading
        labelsStack.distribution = UIStackView.Distribution.fill
        labelsStack.isAccessibilityElement = true
        labelsStack.accessibilityIdentifier = "title"
    }
    
    private func setupContentStack() {
        contentStack.spacing = 16
        contentStack.axis = NSLayoutConstraint.Axis.horizontal
        contentStack.alignment = UIStackView.Alignment.center
        contentStack.distribution = UIStackView.Distribution.fill
        addSubview(contentStack)
    }
    
    private func setupTitleField() {
        titleField.numberOfLines = 1
        titleField.lineBreakMode = .byTruncatingTail
        labelsStack.addArrangedSubview(titleField)
    }
    
    private func setupStyle() {
        titleField.textColor = .from(scheme: .textForeground, variant: .dark)
    }
    
    private func setupSubtitleField() {
        subtitleField.textColor = .whiteAlpha64
        subtitleField.accessibilityIdentifier = "subtitle"
        subtitleField.numberOfLines = 1
        labelsStack.addArrangedSubview(subtitleField)
    }
    
    func configureFont() {
        self.titleField.font = FontSpec(.normal, .light).font!
    }
    
    func setVisualDrawerOffset(_ visualDrawerOffset: CGFloat, notify: Bool) {
        if notify && self.visualDrawerOffset != visualDrawerOffset {
            NotificationCenter.default.post(name: .conversationListItemDidScroll, object: self)
        }
    }
    
    func updateAppearance() {
        titleField.attributedText = titleText
    }
    
    // MARK: - Observer
    @objc
    func contentSizeCategoryDidChange(_ notification: Notification?) {
        configureFont()
    }
    
    @objc
    func otherConversationListItemDidScroll(_ notification: Notification?) {
        guard notification?.object as? ConversationListItemView != self,
              let otherItem = notification?.object as? ConversationListItemView else {
            return
        }
        
        
            
            var fraction: CGFloat
            if bounds.size.width != 0 {
                fraction = 1 - otherItem.visualDrawerOffset / bounds.size.width
            } else {
                fraction = 1
            }
            
            if fraction > 1.0 {
                fraction = 1.0
            } else if fraction < 0.0 {
                fraction = 0.0
            }
            alpha = 0.35 + fraction * 0.65
    }

    private func addMediaPlaybackManagerPlayerStateObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mediaPlayerStateChanged(_:)),
                                               name: .mediaPlaybackManagerPlayerStateChanged,
                                               object: nil)
    }
    
    @objc
    private func mediaPlayerStateChanged(_ notification: Notification?) {
        DispatchQueue.main.async(execute: {
            if self.conversation != nil &&
                AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage?.conversation == self.conversation {
                self.update(for: self.conversation)
            }
        })
    }

}
