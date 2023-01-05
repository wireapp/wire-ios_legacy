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

import UIKit
import WireCommonComponents
import WireDataModel
import WireSyncEngine
import Down

// MARK: - Cells

class ConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration: Equatable {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
    }

}

class ConversationStartedSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let title: NSAttributedString?
        let message: NSAttributedString
        let selectedUsers: [UserType]
        let icon: UIImage?
    }

    private let titleLabel = UILabel()
    private var selectedUsers: [UserType] = []

    override func configureSubviews() {
        super.configureSubviews()

        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        topContentView.addSubview(titleLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        titleLabel.fitIn(view: topContentView)
    }

    func configure(with object: Configuration, animated: Bool) {
        titleLabel.attributedText = object.title
        attributedText = object.message
        imageView.image = object.icon
        imageView.isAccessibilityElement = false
        selectedUsers = object.selectedUsers
        accessibilityLabel = object.title?.string
    }

}

// MARK: - UITextViewDelegate
extension ConversationStartedSystemMessageCell {

    public override func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        delegate?.conversationMessageWantsToOpenParticipantsDetails(self, selectedUsers: selectedUsers, sourceView: self)

        return false
    }

}

class ParticipantsConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration: Equatable {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
        let warning: String?
    }

    private let warningLabel = UILabel()

    override func configureSubviews() {
        super.configureSubviews()
        warningLabel.numberOfLines = 0
        warningLabel.isAccessibilityElement = true
        warningLabel.font = FontSpec(.small, .regular).font
        warningLabel.textColor = SemanticColors.Label.textErrorDefault
        bottomContentView.addSubview(warningLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.fitIn(view: bottomContentView)
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
        warningLabel.text = object.warning
    }
}

class CannotDecryptSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
    }

    var lastConfiguration: Configuration?

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lastConfiguration = object
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
        textLabel.linkTextAttributes = [:]
    }
}

// MARK: - UITextViewDelegate

extension CannotDecryptSystemMessageCell {

    public override func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        delegate?.perform(action: .resetSession, for: message, view: self)

        return false
    }

}

class NewDeviceSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    static let userClientURL: URL = URL(string: "settings://user-client")!

    var linkTarget: LinkTarget?

    enum LinkTarget {
        case user(UserType)
        case conversation(ZMConversation)
    }

    struct Configuration {
        let attributedText: NSAttributedString?
        var icon: UIImage?
        var linkTarget: LinkTarget
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

       setupView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func setupView() {
        lineView.isHidden = false
    }

    func configure(with object: Configuration, animated: Bool) {
        attributedText = object.attributedText
        imageView.image = object.icon
        linkTarget = object.linkTarget
    }

}

// MARK: - UITextViewDelegate

extension NewDeviceSystemMessageCell {

    public override func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        guard let linkTarget = linkTarget,
              url == type(of: self).userClientURL,
              let zClientViewController = ZClientViewController.shared else { return false }

        switch linkTarget {
        case .user(let user):
            zClientViewController.openClientListScreen(for: user)
        case .conversation(let conversation):
            zClientViewController.openDetailScreen(for: conversation)
        }

        return false
    }

}

class ConversationRenamedSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let attributedText: NSAttributedString
        let newConversationName: NSAttributedString
    }

    var nameLabelFont: UIFont? = .normalSemiboldFont
    private let nameLabel = UILabel()

    override func configureSubviews() {
        super.configureSubviews()
        nameLabel.numberOfLines = 0
        imageView.setTemplateIcon(.pencil, size: 16)
        imageView.tintColor = SemanticColors.Icon.backgroundDefault
        bottomContentView.addSubview(nameLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: bottomContentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomContentView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: bottomContentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: bottomContentView.trailingAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = false
        attributedText = object.attributedText
        nameLabel.attributedText = object.newConversationName
        nameLabel.accessibilityLabel = nameLabel.attributedText?.string
    }

}

// MARK: - Factory

final class ConversationSystemMessageCellDescription {

    static func cells(for message: ZMConversationMessage) -> [AnyConversationMessageCellDescription] {
        guard let systemMessageData = message.systemMessageData,
            let sender = message.senderUser,
            let conversation = message.conversationLike else {
            preconditionFailure("Invalid system message")
        }

        switch systemMessageData.systemMessageType {
        case .connectionRequest, .connectionUpdate:
            break // Deprecated

        case .conversationNameChanged:
            guard let newName = systemMessageData.text else {
                fallthrough
            }

            let renamedCell = ConversationRenamedSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, newName: newName)
            return [AnyConversationMessageCellDescription(renamedCell)]

        case .missedCall:
            let missedCallCell = ConversationCallSystemMessageCellDescription(message: message, data: systemMessageData, missed: true)
            return [AnyConversationMessageCellDescription(missedCallCell)]

        case .performedCall:
            let callCell = ConversationCallSystemMessageCellDescription(message: message, data: systemMessageData, missed: false)
            return [AnyConversationMessageCellDescription(callCell)]

        case .messageDeletedForEveryone:
            let senderCell = ConversationSenderMessageCellDescription(sender: sender, message: message)
            return [AnyConversationMessageCellDescription(senderCell)]

        case .messageTimerUpdate:
            guard let timer = systemMessageData.messageTimer else {
                fallthrough
            }

            let timerCell = ConversationMessageTimerCellDescription(message: message, data: systemMessageData, timer: timer, sender: sender)
            return [AnyConversationMessageCellDescription(timerCell)]

        case .conversationIsSecure:
            let shieldCell = ConversationVerifiedSystemMessageSectionDescription()
            return [AnyConversationMessageCellDescription(shieldCell)]

        case .sessionReset:
            let sessionResetCell = ConversationSessionResetSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender)
            return [AnyConversationMessageCellDescription(sessionResetCell)]

        case .decryptionFailed, .decryptionFailedResolved, .decryptionFailed_RemoteIdentityChanged:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender)
            return [AnyConversationMessageCellDescription(decryptionCell)]

        case .newClient, .usingNewDevice, .reactivatedDevice:
            let newClientCell = ConversationNewDeviceSystemMessageCellDescription(message: message, systemMessageData: systemMessageData, conversation: conversation as! ZMConversation)
            return [AnyConversationMessageCellDescription(newClientCell)]

        case .ignoredClient:
            guard let user = systemMessageData.userTypes.first as? UserType else { fallthrough }
            let ignoredClientCell = ConversationIgnoredDeviceSystemMessageCellDescription(message: message, data: systemMessageData, user: user)
            return [AnyConversationMessageCellDescription(ignoredClientCell)]

        case .potentialGap:
            let missingMessagesCell = ConversationMissingMessagesSystemMessageCellDescription(message: message, data: systemMessageData)
            return [AnyConversationMessageCellDescription(missingMessagesCell)]

        case .participantsAdded, .participantsRemoved, .teamMemberLeave:
            let participantsChangedCell = ConversationParticipantsChangedSystemMessageCellDescription(message: message, data: systemMessageData)
            return [AnyConversationMessageCellDescription(participantsChangedCell)]

        case .readReceiptsEnabled,
             .readReceiptsDisabled,
             .readReceiptsOn:
            let cell = ConversationReadReceiptSettingChangedCellDescription(sender: sender,
                                                                            systemMessageType: systemMessageData.systemMessageType)
            return [AnyConversationMessageCellDescription(cell)]

        case .legalHoldEnabled, .legalHoldDisabled:
            let cell = ConversationLegalHoldCellDescription(systemMessageType: systemMessageData.systemMessageType, conversation: conversation as! ZMConversation)
            return [AnyConversationMessageCellDescription(cell)]

        case .newConversation:
            var cells: [AnyConversationMessageCellDescription] = []
            let startedConversationCell = ConversationStartedSystemMessageCellDescription(message: message, data: systemMessageData)
            cells.append(AnyConversationMessageCellDescription(startedConversationCell))

            // Only display invite user cell for team members
            if SelfUser.current.isTeamMember,
               conversation.selfCanAddUsers,
               conversation.isOpenGroup {
                cells.append(AnyConversationMessageCellDescription(GuestsAllowedCellDescription()))
            }

            return cells

        default:
            let unknownMessage = UnknownMessageCellDescription()
            return [AnyConversationMessageCellDescription(unknownMessage)]
        }

        return []
    }
}

private extension ConversationLike {
    var isOpenGroup: Bool {
        return conversationType == .group && allowGuests
    }

    var selfCanAddUsers: Bool {
        return SelfUser.current.canAddUser(to: self)
    }
}

// MARK: - Descriptions

class ConversationParticipantsChangedSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ParticipantsConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let color = SemanticColors.Icon.backgroundDefault
        let textColor = SemanticColors.Label.textDefault

        let model = ParticipantsCellViewModel(font: .mediumFont, largeFont: .largeSemiboldFont, textColor: textColor, iconColor: color, message: message)
        configuration = View.Configuration(icon: model.image(), attributedText: model.attributedTitle(), showLine: true, warning: model.warning())
        accessibilityLabel = model.attributedTitle()?.string
        actionController = nil
    }
}

class ConversationRenamedSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationRenamedSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType, newName: String) {
        let senderText = message.senderName
        let titleString = "content.system.renamed_conv.title".localized(pov: sender.pov, args: senderText)

        let title = NSAttributedString(string: titleString, attributes: [.font: UIFont.mediumFont, .foregroundColor: SemanticColors.Label.textDefault])

        let conversationName = NSAttributedString(string: newName, attributes: [.font: UIFont.normalSemiboldFont, .foregroundColor: SemanticColors.Label.textDefault])
        configuration = View.Configuration(attributedText: title, newConversationName: conversationName)
        actionController = nil
        accessibilityLabel = "\(titleString), \(newName)"
    }

}

class ConversationCallSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, missed: Bool) {
        let viewModel = CallCellViewModel(
            icon: missed ? .endCall : .phone,
            iconColor: missed ? SemanticColors.Icon.backgroundMissedPhoneCall : SemanticColors.Icon.backgroundPhoneCall,
            systemMessageType: data.systemMessageType,
            font: .mediumFont,
            textColor: SemanticColors.Label.textDefault,
            message: message
        )

        configuration = View.Configuration(icon: viewModel.image(), attributedText: viewModel.attributedTitle(), showLine: false)
        accessibilityLabel = viewModel.attributedTitle()?.string
        actionController = nil
    }

    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherDescription = other as? ConversationCallSystemMessageCellDescription else {
            return false
        }

        return self.configuration == otherDescription.configuration
    }
}

class ConversationMessageTimerCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, timer: NSNumber, sender: UserType) {
        let senderText = message.senderName
        let timeoutValue = MessageDestructionTimeoutValue(rawValue: timer.doubleValue)

        var updateText: NSAttributedString?
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.mediumFont, .foregroundColor: SemanticColors.Label.textDefault]

        if timeoutValue == .none {
            updateText = NSAttributedString(string: "content.system.message_timer_off".localized(pov: sender.pov, args: senderText), attributes: baseAttributes)

        } else if let displayString = timeoutValue.displayString {
            let timerString = displayString.replacingOccurrences(of: String.breakingSpace, with: String.nonBreakingSpace)
            updateText = NSAttributedString(string: "content.system.message_timer_changes".localized(pov: sender.pov, args: senderText, timerString), attributes: baseAttributes)
        }

        let icon = StyleKitIcon.hourglass.makeImage(size: 16, color: SemanticColors.Icon.backgroundDefault)
        configuration = View.Configuration(icon: icon, attributedText: updateText, showLine: false)
        accessibilityLabel = updateText?.string
        actionController = nil
    }

}

class ConversationVerifiedSystemMessageSectionDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init() {
        let title = NSAttributedString(
            string: "content.system.is_verified".localized,
            attributes: [.font: UIFont.mediumFont, .foregroundColor: SemanticColors.Label.textDefault]
        )

        configuration = View.Configuration(icon: WireStyleKit.imageOfShieldverified, attributedText: title, showLine: true)
        accessibilityLabel = title.string
        actionController = nil
    }
}

final class ConversationStartedSystemMessageCellDescription: NSObject, ConversationMessageCellDescription {

    typealias View = ConversationStartedSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var conversationObserverToken: Any?

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let color = SemanticColors.Label.textDefault
        let iconColor = SemanticColors.Icon.backgroundDefault
        let model = ParticipantsCellViewModel(font: .mediumFont, largeFont: .largeSemiboldFont, textColor: color, iconColor: iconColor, message: message)

        actionController = nil
        configuration =  View.Configuration(title: model.attributedHeading(),
                                            message: model.attributedTitle() ?? NSAttributedString(string: ""),
                                            selectedUsers: model.selectedUsers,
                                            icon: model.image())
        super.init()
        if !ProcessInfo.processInfo.isRunningTests,
            let conversation = message.conversationLike as? ZMConversation {
            conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
        }
    }

}

extension ConversationStartedSystemMessageCellDescription: ZMConversationObserver {
    func conversationDidChange(_ note: ConversationChangeInfo) {
        guard note.createdRemotelyChanged else { return }
        if let conversation = message?.conversationLike,
           conversation.conversationType == .group,
           conversation.localParticipantsCount == 1 {
            delegate?.conversationMessageShouldUpdate()
        }
    }
}

class ConversationMissingMessagesSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let title = ConversationMissingMessagesSystemMessageCellDescription.makeAttributedString(systemMessageData: data)
        configuration =  View.Configuration(icon: StyleKitIcon.exclamationMark.makeImage(size: .tiny,
                                                                                         color: SemanticColors.Icon.backgroundMissedPhoneCall),
                                            attributedText: title,
                                            showLine: true)
        accessibilityLabel = title.string
        actionController = nil
    }

    private static func makeAttributedString(systemMessageData: ZMSystemMessageData) -> NSAttributedString {
        let font = UIFont.mediumFont
        let boldFont = UIFont.mediumSemiboldFont
        let color = SemanticColors.Label.textDefault

        func attributedLocalizedUppercaseString(_ localizationKey: String, _ users: [AnyHashable]) -> NSAttributedString? {
            guard !users.isEmpty else { return nil }
            let userNames = users.compactMap { ($0 as? UserType)?.name }.joined(separator: ", ")
            let string = localizationKey.localized(args: userNames + " ", users.count) + ". "
                && font && color
            return string
        }

        var title = "content.system.missing_messages.title".localized && font && color

        // We only want to display the subtitle if we have the final added and removed users and either one is not empty
        let addedOrRemovedUsers = !systemMessageData.addedUserTypes.isEmpty || !systemMessageData.removedUserTypes.isEmpty
        if !systemMessageData.needsUpdatingUsers && addedOrRemovedUsers {
            title += "\n\n" + "content.system.missing_messages.subtitle_start".localized + " " && font && color
            title += attributedLocalizedUppercaseString("content.system.missing_messages.subtitle_added", Array(systemMessageData.addedUserTypes))
            title += attributedLocalizedUppercaseString("content.system.missing_messages.subtitle_removed", Array(systemMessageData.removedUserTypes))
        }

        return title
    }

}

class ConversationIgnoredDeviceSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = NewDeviceSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, user: UserType) {
        let title = ConversationIgnoredDeviceSystemMessageCellDescription.makeAttributedString(systemMessage: data, user: user)

        configuration = View.Configuration(attributedText: title, icon: WireStyleKit.imageOfShieldnotverified, linkTarget: .user(user))
        accessibilityLabel = configuration.attributedText?.string
        actionController = nil
    }

    private static func makeAttributedString(systemMessage: ZMSystemMessageData, user: UserType) -> NSAttributedString {
        let string: String
        let link = View.userClientURL.absoluteString

        if user.isSelfUser == true {
            string = "content.system.unverified_self_devices".localized(args: link)
        } else {
            string = "content.system.unverified_other_devices".localized(args: user.name ?? "", link)
        }

        return .markdown(from: string, style: .systemMessage)
    }

}

class ConversationSessionResetSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell

    var message: ZMConversationMessage?
    var delegate: ConversationMessageCellDelegate?
    var actionController: ConversationMessageActionController?

    var topMargin: Float = 0
    var isFullWidth: Bool = true
    var supportsActions: Bool = false
    var showEphemeralTimer: Bool = false
    var containsHighlightableContent: Bool = false
    var accessibilityIdentifier: String?
    var accessibilityLabel: String?

    var configuration: ConversationSystemMessageCell.Configuration

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType) {
        let icon = StyleKitIcon.envelope.makeImage(size: .tiny, color: UIColor.Wire.primaryLabel)
        let title = Self.makeAttributedString(sender)
        configuration = View.Configuration(icon: icon,
                                           attributedText: title,
                                           showLine: true)
        accessibilityLabel = title.string
    }

    static func makeAttributedString(_ sender: UserType) -> NSAttributedString {
        let string: String
        if sender.isSelfUser {
            string =  "content.system.session_reset.self".localized
        } else {
            string = "content.system.session_reset.other".localized(args: sender.name ?? "")
        }

        return NSMutableAttributedString.markdown(from: string, style: .systemMessage)
    }

}

class ConversationCannotDecryptSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = CannotDecryptSystemMessageCell
    let configuration: View.Configuration

    static fileprivate let resetSessionURL: URL = URL(string: "action://reset-session")!

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType) {
        let icon: UIImage
        if data.systemMessageType == .decryptionFailedResolved {
            icon = StyleKitIcon.checkmark.makeImage(size: 16, color: SemanticColors.LegacyColors.strongLimeGreen)
        } else {
            icon = StyleKitIcon.exclamationMark.makeImage(size: 16, color: SemanticColors.LegacyColors.vividRed)
        }

        let title = ConversationCannotDecryptSystemMessageCellDescription
            .makeAttributedString(
                systemMessage: data,
                sender: sender
            )

        configuration = View.Configuration(icon: icon,
                                           attributedText: title,
                                           showLine: false)
        accessibilityLabel = title.string
        actionController = nil
    }

    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherDescription = other as? ConversationCannotDecryptSystemMessageCellDescription else {
            return false
        }

        return configuration.attributedText == otherDescription.configuration.attributedText
    }

    // MARK: - Localization

    private static let BaseLocalizationString = "content.system.cannot_decrypt"
    private static let IdentityString = ".identity"

    private static func makeAttributedString(systemMessage: ZMSystemMessageData, sender: UserType) -> NSAttributedString {

        let messageString = self.messageString(systemMessage.systemMessageType, sender: sender)
        let resetSessionString = self.resetSessionString()
        let errorDetailsString = self.errorDetailsString(
            errorCode: systemMessage.decryptionErrorCode?.intValue ?? 0,
            clientIdentifier: (systemMessage.senderClientID ?? "N/A"))

        var components: [NSAttributedString]

        switch systemMessage.systemMessageType {
        case .decryptionFailed:
            components = [
                messageString
            ]

            if systemMessage.isDecryptionErrorRecoverable {
                components.append(resetSessionString)
            }
        case .decryptionFailedResolved:
            components = [
                messageString,
                errorDetailsString
            ]
        case .decryptionFailed_RemoteIdentityChanged:
            components = [
                messageString
            ]
        default:
            fatal("Incorrect cell configuration")
        }

        return components.joined(separator: NSAttributedString(string: "\n"))
    }

    private static func localizationKey(_ systemMessageType: ZMSystemMessageType) -> String {
        let localizationKey: String
        switch systemMessageType {
        case .decryptionFailed:
            localizationKey = BaseLocalizationString
        case .decryptionFailedResolved:
            localizationKey = BaseLocalizationString + "_resolved"
        case .decryptionFailed_RemoteIdentityChanged:
            localizationKey = BaseLocalizationString + "_identity_changed"
        default:
            fatal("Incorrect cell configuration")
        }

        return localizationKey
    }

    private static func messageString(_ systemMessageType: ZMSystemMessageType, sender: UserType) -> NSAttributedString {

        let name = sender.name ?? ""
        var localizationKey = self.localizationKey(systemMessageType)

        if sender.isSelfUser {
            localizationKey += ".self"
        } else {
            localizationKey += ".other"
        }

        return NSMutableAttributedString.markdown(from: localizationKey.localized(args: name), style: .systemMessage)
    }

    private static func resetSessionString() -> NSAttributedString {
        let string = (BaseLocalizationString + ".reset_session").localized.localizedUppercase

        return NSAttributedString(string: string,
                                  attributes: [.link: resetSessionURL,
                                               .foregroundColor: UIColor.accent(),
                                               .font: UIFont.mediumSemiboldFont])
    }

    private static func errorDetailsString(errorCode: Int, clientIdentifier: String) -> NSAttributedString {
        let string = (BaseLocalizationString + ".error_details").localized(args: errorCode, clientIdentifier)

        return NSAttributedString(string: string.localizedUppercase,
                                  attributes: [.foregroundColor: UIColor.from(scheme: .textPlaceholder),
                                               .font: UIFont.mediumFont])
    }

}

final class ConversationNewDeviceSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = NewDeviceSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, systemMessageData: ZMSystemMessageData, conversation: ZMConversation) {
        configuration = ConversationNewDeviceSystemMessageCellDescription.configuration(for: systemMessageData, in: conversation)
        accessibilityLabel = configuration.attributedText?.string
        actionController = nil
    }

    struct TextAttributes {
        let senderAttributes: [NSAttributedString.Key: AnyObject]
        let startedUsingAttributes: [NSAttributedString.Key: AnyObject]
        let linkAttributes: [NSAttributedString.Key: AnyObject]

        init(boldFont: UIFont, normalFont: UIFont, textColor: UIColor, link: URL) {
            senderAttributes = [.font: boldFont, .foregroundColor: textColor]
            startedUsingAttributes = [.font: normalFont, .foregroundColor: textColor]
            linkAttributes = [.font: normalFont, .link: link as AnyObject]
        }
    }

    private static func configuration(for systemMessage: ZMSystemMessageData, in conversation: ZMConversation) -> View.Configuration {

        let textAttributes = TextAttributes(boldFont: .mediumSemiboldFont, normalFont: .mediumFont, textColor: SemanticColors.Label.textDefault, link: View.userClientURL)
        let clients = systemMessage.clients.compactMap({ $0 as? UserClientType })
        let users = systemMessage.userTypes.lazy
            .compactMap { $0 as? UserType }
            .sorted { $0.name < $1.name }

        if !systemMessage.addedUserTypes.isEmpty {
            return configureForAddedUsers(in: conversation, attributes: textAttributes)
        } else if systemMessage.systemMessageType == .reactivatedDevice {
            return configureForReactivatedSelfClient(SelfUser.current, link: View.userClientURL)
        } else if let user = users.first, user.isSelfUser && systemMessage.systemMessageType == .usingNewDevice {
            return configureForNewCurrentDeviceOfSelfUser(user, link: View.userClientURL)
        } else if users.count == 1, let user = users.first, user.isSelfUser {
            return configureForNewClientOfSelfUser(user, clients: clients, link: View.userClientURL)
        } else {
            return configureForOtherUsers(users, conversation: conversation, clients: clients, attributes: textAttributes)
        }
    }

    private static var verifiedIcon: UIImage {
        return WireStyleKit.imageOfShieldnotverified
    }

    private static var exclamationMarkIcon: UIImage {
        return StyleKitIcon.exclamationMark.makeImage(size: 16, color: SemanticColors.LegacyColors.vividRed)
    }

    private static func configureForReactivatedSelfClient(_ selfUser: UserType, link: URL) -> View.Configuration {
        let string = "content.system.reactivated_device".localized(args: link.absoluteString)
        let attributedText = NSAttributedString.markdown(from: string, style: .systemMessage)
        return View.Configuration(attributedText: attributedText, icon: exclamationMarkIcon, linkTarget: .user(selfUser))
    }

    private static func configureForNewClientOfSelfUser(_ selfUser: UserType, clients: [UserClientType], link: URL) -> View.Configuration {
        let string = "content.system.self_user_new_client".localized(args: link.absoluteString)
        let attributedText = NSMutableAttributedString.markdown(from: string, style: .systemMessage)
        let isSelfClient = clients.first?.isEqual(ZMUserSession.shared()?.selfUserClient) ?? false
        return View.Configuration(attributedText: attributedText, icon: isSelfClient ? nil : verifiedIcon, linkTarget: .user(selfUser))
    }

    private static func configureForNewCurrentDeviceOfSelfUser(_ selfUser: UserType, link: URL) -> View.Configuration {
        let string = "content.system.self_user_new_self_client".localized(args: link.absoluteString)
        let attributedText = NSMutableAttributedString.markdown(from: string, style: .systemMessage)
        return View.Configuration(attributedText: attributedText, icon: nil, linkTarget: .user(selfUser))
    }

    private static func configureForOtherUsers(_ users: [UserType], conversation: ZMConversation, clients: [UserClientType], attributes: TextAttributes) -> View.Configuration {
        let displayNamesOfOthers = users.filter {!$0.isSelfUser }.compactMap { $0.name }
        let firstTwoNames = displayNamesOfOthers.prefix(2)
        let senderNames = firstTwoNames.joined(separator: ", ")
        let additionalSenderCount = max(displayNamesOfOthers.count - 1, 1)

        // %@ %#@d_number_of_others@ started using %#@d_new_devices@
        let senderNamesString = NSString(format: NSLocalizedString("content.system.people_started_using", comment: "") as NSString,
                                         senderNames,
                                         additionalSenderCount,
                                         clients.count) as String

        let userClientString = NSString(format: NSLocalizedString("content.system.new_devices", comment: "") as NSString, clients.count) as String

        var attributedSenderNames = NSAttributedString(string: senderNamesString, attributes: attributes.startedUsingAttributes)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.senderAttributes, toSubstring: senderNames)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.linkAttributes, toSubstring: userClientString)
        let attributedText = attributedSenderNames

        var linkTarget: View.LinkTarget
        if let user = users.first, users.count == 1 {
            linkTarget = .user(user)
        } else {
            linkTarget = .conversation(conversation)
        }

        return View.Configuration(attributedText: attributedText, icon: verifiedIcon, linkTarget: linkTarget)
    }

    private static func configureForAddedUsers(in conversation: ZMConversation, attributes: TextAttributes) -> View.Configuration {
        let attributedNewUsers = NSAttributedString(string: "content.system.new_users".localized, attributes: attributes.startedUsingAttributes)
        let attributedLink = NSAttributedString(string: "content.system.verify_devices".localized, attributes: attributes.linkAttributes)
        let attributedText = attributedNewUsers + " " + attributedLink

        return View.Configuration(attributedText: attributedText, icon: verifiedIcon, linkTarget: .conversation(conversation))
    }

}
