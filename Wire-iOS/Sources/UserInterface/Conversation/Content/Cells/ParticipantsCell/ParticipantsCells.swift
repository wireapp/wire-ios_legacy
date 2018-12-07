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


import Cartography
import TTTAttributedLabel

@objcMembers public class ParticipantsCell: ConversationCell, ParticipantsInvitePeopleViewDelegate, TTTAttributedLabelDelegate {

    private let stackView = UIStackView()
    private let topContainer = UIView()
    private let bottomContainer = UIView()
    private let leftIconView = UIImageView()
    private let leftIconContainer = UIView()
    private let labelView: TTTAttributedLabel = {
        let label = TTTAttributedLabel(frame: .zero)
        label.backgroundColor = .clear
        return label
    }()
    private let nameLabel = UILabel()
    private let verticalInset: CGFloat = 16
    private var lineBaseLineConstraint: NSLayoutConstraint?
    private let inviteView = ParticipantsInvitePeopleView()
    private var viewModel: ParticipantsCellViewModel?
    private var isVisible = true
    
    let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .from(scheme: .separator)
        return view
    }()
    var labelTextColor: UIColor? = .from(scheme: .textForeground)
    var labelTextBlendedColor: UIColor? = .from(scheme: .textDimmed)
    var iconColor: UIColor?

    var labelBoldFont: UIFont? = .mediumSemiboldFont
    var labelLargeFont: UIFont? = .largeSemiboldFont
    
    var attributedText: NSAttributedString? {
        didSet {
            labelView.attributedText = attributedText
            labelView.accessibilityLabel = attributedText?.string
            labelView.addLinks()
        }
    }
    
    let labelFont: UIFont = .mediumFont
    
    /// TTTAttributedLabel needs to be shifted an extra 2pt down so the
    /// line view aligns with the center of the first line.
    private var lineMedianYOffset: CGFloat {
        return 2
    }

    public override required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
        createConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        inviteView.delegate = self
        leftIconView.contentMode = .center
        leftIconView.isAccessibilityElement = true
        leftIconView.accessibilityLabel = "Icon"
        
        nameLabel.numberOfLines = 0
        nameLabel.isAccessibilityElement = true
        labelView.numberOfLines = 0
        labelView.extendsLinkTouchArea = true
        
        labelView.linkAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
            NSAttributedString.Key.foregroundColor: ZMUser.selfUser().accentColor
        ]
        
        labelView.delegate = self
        labelView.isAccessibilityElement = true
        
        stackView.axis = .vertical
        stackView.spacing = verticalInset
        messageContentView.addSubview(stackView)
        
        [topContainer, bottomContainer, inviteView].forEach(stackView.addArrangedSubview)
        
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
        
        constrain(authorLabel, inviteView) { nameLabel, inviteView in
            inviteView.leading == nameLabel.leading
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
        createBaselineConstraint()
        updateLineBaseLineConstraint()
    }
    
    private func createLineViewConstraints() {
        constrain(lineView, contentView, labelView) { lineView, contentView, labelView in
            lineView.leading == labelView.trailing + 16
            lineView.height == .hairline
            lineView.trailing == contentView.trailing
        }
    }
    
    private func createBaselineConstraint() {
        constrain(lineView, labelView, leftIconContainer) { lineView, labelView, icon in
            lineBaseLineConstraint = lineView.centerY == labelView.top
            icon.centerY == lineView.centerY
        }
    }
    
    private func updateLineBaseLineConstraint() {
        lineBaseLineConstraint?.constant = labelFont.median - lineMedianYOffset

        self.layoutIfNeeded()
    }
    
    open override var canResignFirstResponder: Bool {
        return false
    }

    override public func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        reloadInformation(for: message)
    }
    
    public override func willDisplayInTableView() {
        super.willDisplayInTableView()
        isVisible = true
        reloadInformation(for: message)
    }
    
    public override func cellDidEndBeingVisible() {
        super.cellDidEndBeingVisible()
        // this is an optimisation to avoid reloading the cell when it is not
        // visible. Reloading in a large group conversation can be very expensive,
        // as the set of users are sorted for each reload.
        isVisible = false
    }

    private func reloadInformation(for message: ZMConversationMessage) {
        let model = ParticipantsCellViewModel(
            font: labelFont,
            boldFont: labelBoldFont,
            largeFont: labelLargeFont,
            textColor: labelTextColor,
            iconColor: UIColor.from(scheme: .textDimmed),
            message: message
        )

        leftIconView.image = model.image()
        attributedText = model.attributedTitle()
        nameLabel.attributedText = model.attributedHeading()
        topContainer.isHidden = nameLabel.attributedText == nil
        bottomContainer.isHidden = model.sortedUsers.count == 0
        inviteView.isHidden = !model.showInviteButton
        viewModel = model
    }

    open override func update(forMessage changeInfo: MessageChangeInfo!) -> Bool {
        let needsLayout = super.update(forMessage: changeInfo)

        if true == changeInfo.userChangeInfo?.nameChanged, isVisible {
            reloadInformation(for: changeInfo.message)
            return true
        }

        return needsLayout
    }
    
    // MARK: - ParticipantsInvitePeopleViewDelegate
    
    func invitePeopleViewInviteButtonTapped(_ invitePeopleView: ParticipantsInvitePeopleView) {
        delegate?.conversationCell?(self, openGuestOptionsFrom: invitePeopleView.inviteButton)
    }
    
    // MARK: - TTTAttributedLabelDelegate

    public func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        guard url.absoluteString == ParticipantsCellViewModel.showMoreLinkURL.absoluteString else { return }
        guard let model = viewModel else { return }
        delegate?.conversationCell?(self, openParticipantsDetailsWithSelectedUsers: model.selectedUsers, from: self)
    }

}
