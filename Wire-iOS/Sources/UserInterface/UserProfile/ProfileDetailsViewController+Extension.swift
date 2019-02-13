//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension NSAttributedString {
    fileprivate static func readReceiptsText(_ isEnabled: Bool) -> NSAttributedString {
        
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.paragraphSpacing = 8
        paragraph.firstLineHeadIndent = 5
        paragraph.headIndent = 5
        paragraph.tailIndent = -5
        
        let titleFont = UIFont.smallSemiboldFont
        
        let titleText = isEnabled ? "profile.read_receipts_enabled_memo.header".localized : "profile.read_receipts_disabled_memo.header".localized
        
        let title = titleText && [NSAttributedString.Key.font: titleFont,
                                  NSAttributedString.Key.foregroundColor: UIColor.from(scheme: .sectionText),
                                  NSAttributedString.Key.paragraphStyle: paragraph]
        
        let lineBreak = "\n" && [NSAttributedString.Key.paragraphStyle: paragraph]
        
        let textFont = UIFont.mediumFont
        let text = "profile.read_receipts_memo.body".localized && [NSAttributedString.Key.font: textFont,
                                                                   NSAttributedString.Key.foregroundColor: UIColor.from(scheme: .textDimmed),
                                                                   NSAttributedString.Key.paragraphStyle: paragraph]
        
        return title + lineBreak + text
    }
}

extension ProfileDetailsViewController {

    @objc
    func setupViews() {
        createUserImageView()
        createFooter()
        createGuestIndicator()

        view.backgroundColor = UIColor.from(scheme: .contentBackground)
        stackViewContainer = UIView()
        view.addSubview(stackViewContainer)

        teamsGuestIndicator.isHidden = !showGuestLabel
        availabilityView.isHidden = !ZMUser.selfUser().isTeamMember || fullUser().availability == .none

        let remainingTimeString = fullUser().expirationDisplayString
        remainingTimeLabel = UILabel()
        remainingTimeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        remainingTimeLabel.text = remainingTimeString
        remainingTimeLabel.textColor = ColorScheme.default.color(named: .textForeground)
        remainingTimeLabel.font = UIFont.mediumSemiboldFont
        remainingTimeLabel.isHidden = nil == remainingTimeString

        createReadReceiptsEnabledLabel()
        readReceiptsEnabledLabel.isHidden = context != .oneToOneConversation

        let userImageViewWrapper = UIView(frame: CGRect.zero)
        userImageViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        userImageViewWrapper.addSubview(userImageView)

        NSLayoutConstraint.activate([
            userImageView.leadingAnchor.constraint(equalTo: userImageViewWrapper.leadingAnchor, constant: 40),
            userImageView.trailingAnchor.constraint(equalTo: userImageViewWrapper.trailingAnchor, constant: -40),
            userImageView.topAnchor.constraint(equalTo: userImageViewWrapper.topAnchor),
            userImageView.bottomAnchor.constraint(equalTo: userImageViewWrapper.bottomAnchor)
            ])

        stackView = CustomSpacingStackView(customSpacedArrangedSubviews: [
            userImageViewWrapper,
            teamsGuestIndicator,
            remainingTimeLabel,
            availabilityView,
            readReceiptsEnabledLabel
            ])
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.spacing = 0
        stackView.alignment = UIStackView.Alignment.center
        stackViewContainer.addSubview(stackView)

        let verticalSpacing: CGFloat

        if UIScreen.main.isSmall {
            verticalSpacing = 16
        } else {
            verticalSpacing = 32
        }

        stackView.wr_addCustomSpacing(verticalSpacing, after: userImageViewWrapper)

        if remainingTimeLabel.isHidden {
            stackView.wr_addCustomSpacing((availabilityView.isHidden ? (verticalSpacing + 8) : verticalSpacing), after: teamsGuestIndicator)
        } else {
            stackView.wr_addCustomSpacing(8, after: teamsGuestIndicator)
            stackView.wr_addCustomSpacing((availabilityView.isHidden ? (verticalSpacing + 8) : verticalSpacing), after: remainingTimeLabel)
        }

        stackView.wr_addCustomSpacing(verticalSpacing, after: availabilityView)
    }

    @objc func setupStyle() {
        remainingTimeLabel.textColor = .from(scheme: .textDimmed)
        remainingTimeLabel.font = .mediumSemiboldFont
    }

    // MARK: - action menu

    @objc func presentMenuSheetController() {
        actionsController = ConversationActionController(conversation: conversation, target: self)
        actionsController.presentMenu(from: footerView, showConverationNameInMenuTitle: false)
    }
    
    // MARK: - Bottom labels
    
    func createReadReceiptsEnabledLabel() {
        guard let selfUser = ZMUser.selfUser() else {
            return
        }
        
        readReceiptsEnabledLabel = UILabel()
        readReceiptsEnabledLabel.translatesAutoresizingMaskIntoConstraints = false
        readReceiptsEnabledLabel.accessibilityIdentifier = "ReadReceiptsEnabledLabel"
        
        readReceiptsEnabledLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        readReceiptsEnabledLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        readReceiptsEnabledLabel.setContentHuggingPriority(.required, for: .vertical)
        readReceiptsEnabledLabel.setContentHuggingPriority(.required, for: .horizontal)

        readReceiptsEnabledLabel.lineBreakMode = .byWordWrapping
        readReceiptsEnabledLabel.numberOfLines = 0

        readReceiptsEnabledLabel.attributedText = NSAttributedString.readReceiptsText(selfUser.readReceiptsEnabled)
        
        // On small screens the label gets compressed for unknown reason.
        if UIScreen.main.isSmall {
            readReceiptsEnabledLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        }
    }

    // MARK: - footer buttons types


    @objc
    func leftButtonAction() -> ProfileUserAction {
        guard let user = fullUser() else { return .none }

        if user.isSelfUser {
            return .none
        } else if (user.isConnected || user.isTeamMember) &&
            context == .oneToOneConversation {
            if ZMUser.selfUserHas(permissions: .member) || !ZMUser.selfUser().isTeamMember {
                return .addPeople
            } else {
                return .none
            }
        } else if user.isTeamMember {
            return .openConversation
        } else if user.isBlocked {
            return .unblock
        } else if user.isPendingApprovalBySelfUser {
            return .acceptConnectionRequest
        } else if user.isPendingApprovalByOtherUser {
            return .cancelConnectionRequest
        } else if user.canBeConnected {
            return .sendConnectionRequest
        } else if user.isWirelessUser {
            return .none
        } else {
            return .openConversation
        }
    }

    @objc
    func rightButtonAction() -> ProfileUserAction {
        guard let user = fullUser() else { return .none }

        if user.isSelfUser {
            return .none
        } else if context == .groupConversation {
            if ZMUser.selfUser().canRemoveUser(from: conversation) {
                return .removePeople
            } else {
                return .none
            }
        } else if user.isConnected {
            return .presentMenu
        } else if nil != user.team {
            return .presentMenu
        } else {
            return .none
        }
    }
}
