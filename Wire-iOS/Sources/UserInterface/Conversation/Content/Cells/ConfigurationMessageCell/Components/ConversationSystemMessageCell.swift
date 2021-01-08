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
        titleLabel.fitInSuperview()
    }
    
    func configure(with object: Configuration, animated: Bool) {
        titleLabel.attributedText = object.title
        attributedText = object.message
        imageView.image = object.icon
        selectedUsers = object.selectedUsers
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
        warningLabel.textColor = .vividRed
        bottomContentView.addSubview(warningLabel)
    }
    
    override func configureConstraints() {
        super.configureConstraints()
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.fitInSuperview()
    }
    
    // MARK: - Configuration
    
    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
        warningLabel.text = object.warning
    }
}

class LinkConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
        let url: URL
    }

    var lastConfiguration: Configuration?

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lastConfiguration = object
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
    }
}

// MARK: - UITextViewDelegate

extension LinkConversationSystemMessageCell {

    public override func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        if let itemURL = lastConfiguration?.url {
            UIApplication.shared.open(itemURL)
        }

        return false
    }

}


class NewDeviceSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    
    static let userClientURL: URL = URL(string: "settings://user-client")!
    
    var linkTarget: LinkTarget? = nil
    
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
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
        imageView.setIcon(.pencil, size: 16, color: .from(scheme: .textForeground))
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
            let sender = message.sender,
            let conversation = message.conversation else {
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

        case .decryptionFailed:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, remoteIdentityChanged: false)
            return [AnyConversationMessageCellDescription(decryptionCell)]

        case .decryptionFailed_RemoteIdentityChanged:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(message: message, data: systemMessageData, sender: sender, remoteIdentityChanged: true)
            return [AnyConversationMessageCellDescription(decryptionCell)]

        case .newClient, .usingNewDevice, .reactivatedDevice:
            let newClientCell = ConversationNewDeviceSystemMessageCellDescription(message: message, systemMessageData: systemMessageData, conversation: conversation)
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
            let cell = ConversationLegalHoldCellDescription(systemMessageType: systemMessageData.systemMessageType, conversation: conversation)
            return [AnyConversationMessageCellDescription(cell)]
            
        case .newConversation:
            var cells: [AnyConversationMessageCellDescription] = []
            let startedConversationCell = ConversationStartedSystemMessageCellDescription(message: message, data: systemMessageData)
            cells.append(AnyConversationMessageCellDescription(startedConversationCell))
            
            /// only display invite user cell for team members
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

private extension ZMConversation {
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
    let accessibilityLabel: String? = nil
    
    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let color = UIColor.from(scheme: .textForeground)

        let model = ParticipantsCellViewModel(font: .mediumFont, boldFont: .mediumSemiboldFont, largeFont: .largeSemiboldFont, textColor: color, iconColor: color, message: message)
        configuration = View.Configuration(icon: model.image(), attributedText: model.attributedTitle(), showLine: true, warning: model.warning())
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
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType, newName: String) {
        let senderText = message.senderName
        let titleString = "content.system.renamed_conv.title".localized(pov: sender.pov, args: senderText)

        let title = NSAttributedString(string: titleString, attributes: [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)])
            .adding(font: .mediumSemiboldFont, to: senderText)

        let conversationName = NSAttributedString(string: newName, attributes: [.font: UIFont.normalSemiboldFont, .foregroundColor: UIColor.from(scheme: .textForeground)])
        configuration = View.Configuration(attributedText: title, newConversationName: conversationName)
        actionController = nil
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
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, missed: Bool) {
        let viewModel = CallCellViewModel(
            icon: missed ? .endCall : .phone,
            iconColor: UIColor(for: missed ? .vividRed : .strongLimeGreen),
            systemMessageType: data.systemMessageType,
            font: .mediumFont,
            boldFont: .mediumSemiboldFont,
            textColor: .from(scheme: .textForeground),
            message: message
        )

        configuration = View.Configuration(icon: viewModel.image(), attributedText: viewModel.attributedTitle(), showLine: false)
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
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, timer: NSNumber, sender: UserType) {
        let senderText = message.senderName
        let timeoutValue = MessageDestructionTimeoutValue(rawValue: timer.doubleValue)

        var updateText: NSAttributedString? = nil
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)]

        if timeoutValue == .none {
            updateText = NSAttributedString(string: "content.system.message_timer_off".localized(pov: sender.pov, args: senderText), attributes: baseAttributes)
                .adding(font: .mediumSemiboldFont, to: senderText)

        } else if let displayString = timeoutValue.displayString {
            let timerString = displayString.replacingOccurrences(of: String.breakingSpace, with: String.nonBreakingSpace)
            updateText = NSAttributedString(string: "content.system.message_timer_changes".localized(pov: sender.pov, args: senderText, timerString), attributes: baseAttributes)
                .adding(font: .mediumSemiboldFont, to: senderText)
                .adding(font: .mediumSemiboldFont, to: timerString)
        }

        let icon = StyleKitIcon.hourglass.makeImage(size: 16, color: UIColor.from(scheme: .textDimmed))
        configuration = View.Configuration(icon: icon, attributedText: updateText, showLine: false)
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
    let accessibilityLabel: String? = nil

    init() {
        let title = NSAttributedString(
            string: "content.system.is_verified".localized,
            attributes: [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)]
        )

        configuration = View.Configuration(icon: WireStyleKit.imageOfShieldverified, attributedText: title, showLine: true)
        actionController = nil
    }
}

class ConversationStartedSystemMessageCellDescription: NSObject, ConversationMessageCellDescription {
    
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
        let color = UIColor.from(scheme: .textForeground)
        let model = ParticipantsCellViewModel(font: .mediumFont, boldFont: .mediumSemiboldFont, largeFont: .largeSemiboldFont, textColor: color, iconColor: color, message: message)
        
        actionController = nil
        configuration =  View.Configuration(title: model.attributedHeading(),
                                            message: model.attributedTitle() ?? NSAttributedString(string: ""),
                                            selectedUsers: model.selectedUsers,
                                            icon: model.image())
        super.init()
        if let conversation = message.conversation {
            conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
        }
    }
    
}

extension ConversationStartedSystemMessageCellDescription: ZMConversationObserver {
    public func conversationDidChange(_ note: ConversationChangeInfo) {
        guard note.createdRemotelyChanged else { return }
        if let conversation = message?.conversation, conversation.conversationType == .group, conversation.localParticipants.count == 1 {
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
    let accessibilityLabel: String? = nil
    
    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let title = ConversationMissingMessagesSystemMessageCellDescription.makeAttributedString(systemMessageData: data)
        configuration =  View.Configuration(icon: StyleKitIcon.exclamationMark.makeImage(size: .tiny, color: .vividRed), attributedText: title, showLine: true)
        actionController = nil
    }
    
    private static func makeAttributedString(systemMessageData: ZMSystemMessageData) -> NSAttributedString {
        let font = UIFont.mediumFont
        let boldFont = UIFont.mediumSemiboldFont
        let color = UIColor.from(scheme: .textForeground)
        
        func attributedLocalizedUppercaseString(_ localizationKey: String, _ users: [AnyHashable]) -> NSAttributedString? {
            guard !users.isEmpty else { return nil }
            let userNames = users.compactMap { ($0 as? UserType)?.name }.joined(separator: ", ")
            let string = localizationKey.localized(args: userNames + " ", users.count) + ". "
                && font && color
            return string.addAttributes([.font: boldFont], toSubstring: userNames)
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
    let accessibilityLabel: String? = nil
    
    init(message: ZMConversationMessage, data: ZMSystemMessageData, user: UserType) {
        let title = ConversationIgnoredDeviceSystemMessageCellDescription.makeAttributedString(systemMessage: data, user: user)
        
        configuration =  View.Configuration(attributedText: title, icon: WireStyleKit.imageOfShieldnotverified, linkTarget: .user(user))
        actionController = nil
    }
    
    private static func makeAttributedString(systemMessage: ZMSystemMessageData, user: UserType) -> NSAttributedString {
        
        let youString = "content.system.you_started".localized
        let deviceString : String
        
        if user.isSelfUser == true {
            deviceString = "content.system.your_devices".localized
        } else {
            deviceString = String(format: "content.system.other_devices".localized, user.name ?? "")
        }
        
        let baseString = "content.system.unverified".localized
        let endResult = String(format: baseString, youString, deviceString)
        
        let youRange = (endResult as NSString).range(of: youString)
        let deviceRange = (endResult as NSString).range(of: deviceString)
        
        let attributedString = NSMutableAttributedString(string: endResult)
        attributedString.addAttributes([.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)], range:NSRange(location: 0, length: endResult.count))
        attributedString.addAttributes([.font: UIFont.mediumSemiboldFont, .foregroundColor: UIColor.from(scheme: .textForeground)], range: youRange)
        attributedString.addAttributes([.font: UIFont.mediumFont, .link: View.userClientURL], range: deviceRange)
        
        return  NSAttributedString(attributedString: attributedString)
    }
    
}

class ConversationCannotDecryptSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = LinkConversationSystemMessageCell
    let configuration: View.Configuration

    static fileprivate let generalErrorURL : URL = URL(string:"action://general-error")!
    static fileprivate let remoteIDErrorURL : URL = URL(string:"action://remote-id-error")!

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType, remoteIdentityChanged: Bool) {
        let exclamationColor = UIColor(for: .vividRed)
        let icon = StyleKitIcon.exclamationMark.makeImage(size: 16, color: exclamationColor)
        let link: URL = remoteIdentityChanged ? .wr_cannotDecryptNewRemoteIDHelp : .wr_cannotDecryptHelp

        let title = ConversationCannotDecryptSystemMessageCellDescription
            .makeAttributedString(
                systemMessage: data,
                sender: sender,
                remoteIDChanged:
                remoteIdentityChanged,
                link: link
            )

        configuration = View.Configuration(icon: icon, attributedText: title, showLine: false, url: link)
        actionController = nil
    }

    // MARK: - Localization

    private static let BaseLocalizationString = "content.system.cannot_decrypt"
    private static let IdentityString = ".identity"

    private static func makeAttributedString(systemMessage: ZMSystemMessageData, sender: UserType, remoteIDChanged: Bool, link: URL) -> NSAttributedString {
        let name = localizedWhoPart(sender, remoteIDChanged: remoteIDChanged)

        let why = NSAttributedString(string: localizedWhyPart(remoteIDChanged),
                                     attributes: [.font: UIFont.mediumFont, .link: link as AnyObject, .foregroundColor: UIColor.from(scheme: .textForeground)])

        let device : NSAttributedString
        if Bundle.developerModeEnabled {
            device = "\n" + NSAttributedString(string: localizedDevice(systemMessage.clients.first as? UserClient),
                                               attributes: [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textDimmed)])
        } else {
            device = NSAttributedString()
        }

        let messageString = NSAttributedString(string: localizedWhatPart(remoteIDChanged, name: name),
                                               attributes: [.font: UIFont.mediumFont, .foregroundColor: UIColor.from(scheme: .textForeground)])

        let fullString = messageString + " " + why + device
        return fullString.addAttributes([.font: UIFont.mediumSemiboldFont], toSubstring:name)
    }

    private static func localizedWhoPart(_ sender: UserType, remoteIDChanged: Bool) -> String {
        switch (sender.isSelfUser, remoteIDChanged) {
        case (true, _):
            return (BaseLocalizationString + (remoteIDChanged ? IdentityString : "") + ".you_part").localized
        case (false, true):
            return (BaseLocalizationString + IdentityString + ".otherUser_part").localized(args: sender.name ?? "")
        case (false, false):
            return sender.name ?? ""
        }
    }

    private static func localizedWhatPart(_ remoteIDChanged: Bool, name: String) -> String {
        return (BaseLocalizationString + (remoteIDChanged ? IdentityString : "")).localized(args: name)
    }

    private static func localizedWhyPart(_ remoteIDChanged: Bool) -> String {
        return (BaseLocalizationString + (remoteIDChanged ? IdentityString : "")+".why_part").localized
    }

    private static func localizedDevice(_ device: UserClient?) -> String {
        return (BaseLocalizationString + ".otherDevice_part").localized(args: device?.remoteIdentifier ?? "-")
    }

}

class ConversationNewDeviceSystemMessageCellDescription: ConversationMessageCellDescription {
    
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
    let accessibilityLabel: String? = nil
    
    init(message: ZMConversationMessage, systemMessageData: ZMSystemMessageData, conversation: ZMConversation) {
        configuration = ConversationNewDeviceSystemMessageCellDescription.configuration(for: systemMessageData, in: conversation)
        actionController = nil
    }
    
    struct TextAttributes {
        let senderAttributes : [NSAttributedString.Key: AnyObject]
        let startedUsingAttributes : [NSAttributedString.Key: AnyObject]
        let linkAttributes : [NSAttributedString.Key: AnyObject]
        
        init(boldFont: UIFont, normalFont: UIFont, textColor: UIColor, link: URL) {
            senderAttributes = [.font: boldFont, .foregroundColor: textColor]
            startedUsingAttributes = [.font: normalFont, .foregroundColor: textColor]
            linkAttributes = [.font: normalFont, .link: link as AnyObject]
        }
    }
    
    private static func configuration(for systemMessage: ZMSystemMessageData, in conversation: ZMConversation) -> View.Configuration {
        
        let textAttributes = TextAttributes(boldFont: .mediumSemiboldFont, normalFont: .mediumFont, textColor: UIColor.from(scheme: .textForeground), link: View.userClientURL)
        let clients = systemMessage.clients.compactMap ({ $0 as? UserClientType })
        let users = systemMessage.userTypes.lazy
            .compactMap { $0 as? UserType }
            .sorted { $0.name < $1.name }
        
        if !systemMessage.addedUserTypes.isEmpty {
            return configureForAddedUsers(in: conversation, attributes: textAttributes)
        } else if systemMessage.systemMessageType == .reactivatedDevice {
            return configureForReactivatedSelfClient(ZMUser.selfUser(), attributes: textAttributes)
        } else if let user = users.first, user.isSelfUser && systemMessage.systemMessageType == .usingNewDevice {
            return configureForNewCurrentDeviceOfSelfUser(user, attributes: textAttributes)
        } else if users.count == 1, let user = users.first, user.isSelfUser {
            return configureForNewClientOfSelfUser(user, clients: clients, attributes: textAttributes)
        } else {
            return configureForOtherUsers(users, conversation: conversation, clients: clients, attributes: textAttributes)
        }
    }
    
    private static var verifiedIcon: UIImage {
        return WireStyleKit.imageOfShieldnotverified
    }

    private static var exclamationMarkIcon: UIImage {
        return StyleKitIcon.exclamationMark.makeImage(size: 16, color: .vividRed)
    }
    
    private static func configureForReactivatedSelfClient(_ selfUser: UserType, attributes: TextAttributes) -> View.Configuration {
        let deviceString = NSLocalizedString("content.system.this_device", comment: "")
        let fullString  = String(format: NSLocalizedString("content.system.reactivated_device", comment: ""), deviceString) && attributes.startedUsingAttributes
        let attributedText = fullString.setAttributes(attributes.linkAttributes, toSubstring: deviceString)
        
        return View.Configuration(attributedText: attributedText, icon: exclamationMarkIcon, linkTarget: .user(selfUser))
    }
    
    private static func configureForNewClientOfSelfUser(_ selfUser: UserType, clients: [UserClientType], attributes: TextAttributes) -> View.Configuration {
        let isSelfClient = clients.first?.isEqual(ZMUserSession.shared()?.selfUserClient) ?? false
        let senderName = NSLocalizedString("content.system.you_started", comment: "") && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "") && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.new_device", comment: "") && attributes.linkAttributes
        let attributedText = senderName + "general.space_between_words".localized + startedUsingString + "general.space_between_words".localized + userClientString
        
        return View.Configuration(attributedText: attributedText, icon: isSelfClient ? nil : verifiedIcon, linkTarget: .user(selfUser))
    }
    
    private static func configureForNewCurrentDeviceOfSelfUser(_ selfUser: UserType, attributes: TextAttributes) -> View.Configuration {
        let senderName = NSLocalizedString("content.system.you_started", comment: "") && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "") && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.this_device", comment: "") && attributes.linkAttributes
        let attributedText = senderName + "general.space_between_words".localized + startedUsingString + "general.space_between_words".localized + userClientString
        
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

