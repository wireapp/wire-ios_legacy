//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireShareEngine

class ConversationStateAccessoryView: UIView {

    private let contentStack = UIStackView()
    private let legalHoldImageView = UIImageView()
    private let verifiedImageView = UIImageView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        contentStack.axis = .horizontal
        contentStack.distribution = .fillEqually
        contentStack.alignment = .fill
        contentStack.spacing = 8

        legalHoldImageView.setContentHuggingPriority(.required, for: .horizontal)
        legalHoldImageView.setIcon(.legalholdactive, size: 16, color: .vividRed)
        contentStack.addArrangedSubview(legalHoldImageView)

        verifiedImageView.setContentHuggingPriority(.required, for: .horizontal)
        contentStack.addArrangedSubview(verifiedImageView)

        addSubview(contentStack)
    }

    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configuration

    func prepareForReuse() {
        legalHoldImageView.isHidden = true
        verifiedImageView.isHidden = true
        verifiedImageView.image = nil
    }

    func configure(for conversation: Conversation) {
        legalHoldImageView.isHidden = !conversation.legalHoldStatus.denotesEnabledComplianceDevice

        if let verificationImage = iconForVerificationLevel(in: conversation) {
            verifiedImageView.image = verificationImage
            verifiedImageView.isHidden = false
        } else {
            verifiedImageView.isHidden = true
            verifiedImageView.image = nil
        }
    }

    private func iconForVerificationLevel(in conversation: Conversation) -> UIImage? {
        switch conversation.securityLevel {
        case .secure:
            return WireStyleKit.imageOfShieldverified
        case .secureWithIgnored:
            return WireStyleKit.imageOfShieldnotverified
        case .notSecure:
            return nil
        }
    }

}
