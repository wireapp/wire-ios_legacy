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


import Classy
import Cartography


public class ParticipantsCell: ConversationCell {

    private let collectionViewController = ParticipantsCollectionViewController<ParticipantsUserCell>()
    private let stackView = UIStackView()
    private let topContainer = UIView()
    private let bottomContainer = UIView()
    private let leftIconView = UIImageView()
    private let leftIconContainer = UIView()
    private let labelView = UILabel()
    private let nameLabel = UILabel()
    private let verticalInset: CGFloat = 16
    private var lineBaseLineConstraint: NSLayoutConstraint?
    
    // Classy
    let lineView = UIView()
    var labelTextColor, labelTextBlendedColor: UIColor?
    var labelBoldFont, labelLargeFont: UIFont?
    
    var attributedText: NSAttributedString? {
        didSet {
            labelView.attributedText = attributedText
            labelView.accessibilityLabel = attributedText?.string
        }
    }
    
    var labelFont: UIFont? {
        didSet {
            updateLineBaseLineConstraint()
        }
    }

    public override required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupCollectionView()
        createConstraints()
        CASStyler.default().styleItem(self)
    }

    private func setupCollectionView() {
        // Cells should not be selectable (for now)
        collectionViewController.collectionView.isUserInteractionEnabled = false
        bottomContainer.addSubview(collectionViewController.view)

        collectionViewController.configureCell = { [weak self] user, cell in
            cell.user = user
            cell.dimmed = self?.message.systemMessageData?.systemMessageType == .participantsRemoved
        }

        collectionViewController.selectAction = { [weak self] user, cell in
            guard let `self` = self else { return }
            self.delegate.conversationCell?(self, userTapped: user, in: cell)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        leftIconView.contentMode = .center
        leftIconView.isAccessibilityElement = true
        leftIconView.accessibilityLabel = "Icon"
        
        nameLabel.numberOfLines = 0
        nameLabel.isAccessibilityElement = true
        labelView.numberOfLines = 0
        labelView.isAccessibilityElement = true

        stackView.axis = .vertical
        stackView.spacing = verticalInset
        messageContentView.addSubview(stackView)
        [topContainer, bottomContainer].forEach(stackView.addArrangedSubview)
        topContainer.addSubview(nameLabel)
        bottomContainer.addSubview(leftIconContainer)
        leftIconContainer.addSubview(leftIconView)
        bottomContainer.addSubview(labelView)
        bottomContainer.addSubview(lineView)
        
        var accessibilityElements = self.accessibilityElements ?? []
        accessibilityElements += [nameLabel, labelView, leftIconView]
        self.accessibilityElements = accessibilityElements
    }
    
    private func createConstraints() {
        constrain(stackView, messageContentView) { stackView, messageContentView in
            stackView.top == messageContentView.top + verticalInset
            stackView.leading == messageContentView.leading
            stackView.trailing == messageContentView.trailing
            stackView.bottom == messageContentView.bottom - verticalInset
        }
        
        constrain(leftIconContainer, leftIconView, labelView, messageContentView, authorLabel) { leftIconContainer, leftIconView, labelView, messageContentView, authorLabel in
            leftIconContainer.leading == messageContentView.leading
            leftIconContainer.trailing == authorLabel.leading
            leftIconContainer.bottom <= messageContentView.bottom
            leftIconContainer.height == leftIconView.height
            leftIconView.center == leftIconContainer.center
            leftIconView.height == 16
            leftIconView.height == leftIconView.width
            labelView.leading == leftIconContainer.trailing
            labelView.trailing <= messageContentView.trailing - 72
        }
        
        constrain(nameLabel, labelView, messageContentView, leftIconContainer, bottomContainer) { nameLabel, labelView, messageContentView, leftIconContainer, bottomContainer in
            labelView.top == bottomContainer.top
            nameLabel.leading == leftIconContainer.trailing
            nameLabel.trailing <= messageContentView.trailing - 72
            labelView.bottom <= bottomContainer.bottom
            messageContentView.height >= 32
        }
        
        constrain(nameLabel, topContainer) { nameLabel, topContainer in
            nameLabel.top == topContainer.top
            nameLabel.bottom == topContainer.bottom
        }
        
        createLineViewConstraints()
        updateLineBaseLineConstraint()
        createBaselineConstraint()
        
        constrain(messageContentView, labelView, collectionViewController.view, bottomContainer) { container, label, participants, bottomContainer in
            participants.leading == label.leading
            participants.trailing == container.trailing - 72
            participants.top == label.bottom + 8
            participants.bottom == bottomContainer.bottom
        }
    }
    
    private func createLineViewConstraints() {
        constrain(lineView, contentView, labelView, messageContentView) { lineView, contentView, labelView, messageContentView in
            lineView.leading == labelView.trailing + 16
            lineView.height == .hairline
            lineView.trailing == contentView.trailing
        }
    }
    
    private func createBaselineConstraint() {
        constrain(lineView, labelView, leftIconContainer) { lineView, labelView, icon in
            lineBaseLineConstraint = lineView.centerY == labelView.top + self.labelView.font.median
            icon.centerY == lineView.centerY
        }
    }
    
    private func updateLineBaseLineConstraint() {
        guard let font = labelFont else { return }
        lineBaseLineConstraint?.constant = font.median
    }
    
    open override var canResignFirstResponder: Bool {
        return false
    }

    override public func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        let model = ParticipantsCellViewModel(font: labelFont, boldFont: labelBoldFont, largeFont: labelLargeFont, textColor: labelTextColor, message: message)
        leftIconView.image = model.image()
        attributedText = model.attributedTitle()
        nameLabel.attributedText = model.attributedHeading()
        topContainer.isHidden = nameLabel.attributedText == nil
        bottomContainer.isHidden = model.sortedUsers().count == 0
        // We need a layout pass here in order for the collectionView to pick up the correct size
        setNeedsLayout()
        layoutIfNeeded()
        collectionViewController.users = model.sortedUsers()
    }

}
