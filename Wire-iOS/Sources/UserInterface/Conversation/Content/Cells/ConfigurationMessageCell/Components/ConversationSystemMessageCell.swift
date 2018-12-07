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
import TTTAttributedLabel

// MARK: - Cells

class ConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    struct Configuration {
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

class ParticipantsConversationSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    
    struct Configuration {
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
        contentView.addSubview(warningLabel)
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

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let itemURL = lastConfiguration?.url {
            UIApplication.shared.open(itemURL)
        }
    }

}

class NewDeviceSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    
    static let userClientURL: URL = URL(string: "settings://user-client")!
    
    var linkTarget: LinkTarget? = nil
    
    enum LinkTarget {
        case user(ZMUser)
        case conversation(ZMConversation)
    }
    
    struct Configuration {
        let attributedText: NSAttributedString?
        let showIcon: Bool
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
        imageView.image  = WireStyleKit.imageOfShieldnotverified
        lineView.isHidden = false
    }
    
    func configure(with object: Configuration, animated: Bool) {
        attributedText = object.attributedText
        imageView.isHidden = !object.showIcon
        linkTarget = object.linkTarget
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith URL: URL!) {
        guard let linkTarget = linkTarget  else { return }
        
        if URL == type(of: self).userClientURL {
            switch linkTarget {
            case .user(let user):
                ZClientViewController.shared()?.openClientListScreen(for: user)
            case .conversation(let conversation):
                ZClientViewController.shared()?.openDetailScreen(for: conversation)
            }
        }
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
        imageView.image = UIImage(for: .pencil, fontSize: 16, color: .from(scheme: .textForeground))
        contentView.addSubview(nameLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
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

class ConversationSystemMessageCellDescription {

    static func cells(for message: ZMConversationMessage, layoutProperties: ConversationCellLayoutProperties) -> [AnyConversationMessageCellDescription] {
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

        case .newClient, .usingNewDevice:
            let newClientCell = ConversationNewDeviceSystemMessageCellDescription(message: message, systemMessageData: systemMessageData, conversation: conversation)
            return [AnyConversationMessageCellDescription(newClientCell)]

        case .ignoredClient:
            let ignoredClientCell = ConversationLegacyCellDescription<ConversationIgnoredDeviceCell>(message: message, layoutProperties: layoutProperties)
            return [AnyConversationMessageCellDescription(ignoredClientCell)]

        case .potentialGap, .reactivatedDevice:
            let missingMessagesCell = ConversationLegacyCellDescription<MissingMessagesCell>(message: message, layoutProperties: layoutProperties)
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

        case .newConversation:
            let participantsCell = ConversationLegacyCellDescription<ParticipantsCell>(message: message, layoutProperties: layoutProperties)
            return [AnyConversationMessageCellDescription(participantsCell)]

        default:
            let unknownMessage = UnknownMessageCellDescription()
            return [AnyConversationMessageCellDescription(unknownMessage)]
        }

        return []
    }

}

// MARK: - Descriptions


class ConversationParticipantsChangedSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ParticipantsConversationSystemMessageCell
    let configuration: View.Configuration
    
    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
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
    weak var delegate: ConversationCellDelegate? 
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: ZMUser, newName: String) {
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
    weak var delegate: ConversationCellDelegate? 
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
}

class ConversationMessageTimerCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate? 
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, timer: NSNumber, sender: ZMUser) {
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

        let icon = UIImage(for: .hourglass, fontSize: 16, color: UIColor.from(scheme: .textDimmed))
        configuration = View.Configuration(icon: icon, attributedText: updateText, showLine: false)
        actionController = nil
    }

}

class ConversationVerifiedSystemMessageSectionDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate? 
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

class ConversationCannotDecryptSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = LinkConversationSystemMessageCell
    let configuration: View.Configuration

    static fileprivate let generalErrorURL : URL = URL(string:"action://general-error")!
    static fileprivate let remoteIDErrorURL : URL = URL(string:"action://remote-id-error")!

    var message: ZMConversationMessage?
    weak var delegate: ConversationCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: ZMUser, remoteIdentityChanged: Bool) {
        let exclamationColor = UIColor(for: .vividRed)
        let icon = UIImage(for: .exclamationMark, fontSize: 16, color: exclamationColor)
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

    private static func makeAttributedString(systemMessage: ZMSystemMessageData, sender: ZMUser, remoteIDChanged: Bool, link: URL) -> NSAttributedString {
        let name = localizedWhoPart(sender, remoteIDChanged: remoteIDChanged)

        let why = NSAttributedString(string: localizedWhyPart(remoteIDChanged),
                                     attributes: [.font: UIFont.mediumFont, .link: link as AnyObject, .foregroundColor: UIColor.from(scheme: .textForeground)])

        let device : NSAttributedString
        if DeveloperMenuState.developerMenuEnabled() {
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

    private static func localizedWhoPart(_ sender: ZMUser, remoteIDChanged: Bool) -> String {
        switch (sender.isSelfUser, remoteIDChanged) {
        case (true, _):
            return (BaseLocalizationString + (remoteIDChanged ? IdentityString : "") + ".you_part").localized
        case (false, true):
            return (BaseLocalizationString + IdentityString + ".otherUser_part").localized(args: sender.displayName)
        case (false, false):
            return sender.displayName
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
    weak var delegate: ConversationCellDelegate?
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
        let users = systemMessage.users.sorted(by: { (a: ZMUser, b: ZMUser) -> Bool in
            a.displayName.compare(b.displayName) == ComparisonResult.orderedAscending
        })
        
        if !systemMessage.addedUsers.isEmpty {
            return configureForAddedUsers(in: conversation, attributes: textAttributes)
        } else if let user = users.first , user.isSelfUser && systemMessage.systemMessageType == .usingNewDevice {
            return configureForNewCurrentDeviceOfSelfUser(user, attributes: textAttributes)
        } else if users.count == 1, let user = users.first , user.isSelfUser {
            return configureForNewClientOfSelfUser(user, clients: clients, attributes: textAttributes)
        } else {
            return configureForOtherUsers(users, conversation: conversation, clients: clients, attributes: textAttributes)
        }
    }
    
    private static func configureForNewClientOfSelfUser(_ selfUser: ZMUser, clients: [UserClientType], attributes: TextAttributes) -> View.Configuration {
        let isSelfClient = clients.first?.isEqual(ZMUserSession.shared()?.selfUserClient()) ?? false
        let senderName = NSLocalizedString("content.system.you_started", comment: "") && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "") && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.new_device", comment: "") && attributes.linkAttributes
        let attributedText = senderName + "general.space_between_words".localized + startedUsingString + "general.space_between_words".localized + userClientString
        
        return View.Configuration(attributedText: attributedText, showIcon: !isSelfClient, linkTarget: .user(selfUser))
    }
    
    private static func configureForNewCurrentDeviceOfSelfUser(_ selfUser: ZMUser, attributes: TextAttributes) -> View.Configuration {
        let senderName = NSLocalizedString("content.system.you_started", comment: "") && attributes.senderAttributes
        let startedUsingString = NSLocalizedString("content.system.started_using", comment: "") && attributes.startedUsingAttributes
        let userClientString = NSLocalizedString("content.system.this_device", comment: "") && attributes.linkAttributes
        let attributedText = senderName + "general.space_between_words".localized + startedUsingString + "general.space_between_words".localized + userClientString
        
        return View.Configuration(attributedText: attributedText, showIcon: false, linkTarget: .user(selfUser))
    }
    
    private static func configureForOtherUsers(_ users: [ZMUser], conversation: ZMConversation, clients: [UserClientType], attributes: TextAttributes) -> View.Configuration {
        let displayNamesOfOthers = users.filter {!$0.isSelfUser }.compactMap {$0.displayName as String}
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
       
        return View.Configuration(attributedText: attributedText, showIcon: true, linkTarget: linkTarget)
    }
    
    private static func configureForAddedUsers(in conversation: ZMConversation, attributes: TextAttributes) -> View.Configuration {
        let attributedNewUsers = NSAttributedString(string: "content.system.new_users".localized, attributes: attributes.startedUsingAttributes)
        let attributedLink = NSAttributedString(string: "content.system.verify_devices".localized, attributes: attributes.linkAttributes)
        let attributedText = attributedNewUsers + " " + attributedLink
        
        return View.Configuration(attributedText: attributedText, showIcon: true, linkTarget: .conversation(conversation))
    }
    
}

