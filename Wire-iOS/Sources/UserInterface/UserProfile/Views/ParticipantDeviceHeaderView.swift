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
import UIKit

protocol ParticipantDeviceHeaderViewDelegate: AnyObject {
    func participantsDeviceHeaderViewDidTapLearnMore(_ headerView: ParticipantDeviceHeaderView)
}

final class ParticipantDeviceHeaderView: UIView {
    private var font: UIFont = .normalLightFont
    private var textColor: UIColor = SemanticColors.Label.textSectionHeader
    private var linkAttributeColor: UIColor = .accent()
    private var textView: WebLinkTextView = WebLinkTextView()
    let userName: String

    weak var delegate: ParticipantDeviceHeaderViewDelegate?
    var showUnencryptedLabel = false {
        didSet {
            textView.attributedText = attributedExplanationText(for: userName, showUnencryptedLabel: showUnencryptedLabel)
        }
    }

    init(userName: String) {
        self.userName = userName

        super.init(frame: CGRect.zero)

        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundColor = .clear
        setupViews()
        setupConstraints()
        setupAccessibility()
    }

    func setupViews() {
        textView.textContainer.maximumNumberOfLines = 0
        textView.delegate = self
        textView.linkTextAttributes = [:]

        addSubview(textView)
    }

    // MARK: Attributed Text

    func attributedExplanationText(for userName: String,
                                   showUnencryptedLabel unencrypted: Bool) -> NSAttributedString? {
        if unencrypted {
            let message = "profile.devices.fingerprint_message_unencrypted".localized
            return attributedFingerprint(forUserName: userName, message: message)
        } else {
            let message = "\("profile.devices.fingerprint_message.title".localized)\("general.space_between_words".localized)"

            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedFingerprint(forUserName: userName, message: message))

            let fingerprintLearnMoreLink = "profile.devices.fingerprint_message.link".localized && linkAttributes

            return mutableAttributedString + fingerprintLearnMoreLink
        }
    }

    func attributedFingerprint(forUserName userName: String, message: String) -> NSAttributedString {
        let fingerprintExplanation = String(format: message, userName)

        let textAttributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyleForFingerprint
        ]

        return NSAttributedString(string: fingerprintExplanation, attributes: textAttributes)
    }

    var linkAttributes: [NSAttributedString.Key: Any] {
        return [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: linkAttributeColor,
            NSAttributedString.Key.link: NSURL.wr_fingerprintLearnMoreURL,
            NSAttributedString.Key.paragraphStyle: paragraphStyleForFingerprint
        ]
    }

    var paragraphStyleForFingerprint: NSMutableParagraphStyle {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineSpacing = 2

        return paragraphStyle
    }

    private func setupConstraints() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private func setupAccessibility() {
        textView.accessibilityTraits = .link
        textView.accessibilityHint = L10n.Accessibility.DeviceDetails.WhyVerifyFingerprint.hint
    }
}

extension ParticipantDeviceHeaderView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.participantsDeviceHeaderViewDidTapLearnMore(self)

        return false
    }
}
