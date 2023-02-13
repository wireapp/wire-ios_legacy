//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import WireCommonComponents

extension CallStatusViewState {
    typealias CallStatus = L10n.Localizable.Call.Status

    var isIncoming: Bool {
        switch self {
        case .ringingIncoming: return true
        default: return false
        }
    }
    var requiresShowingStatusView: Bool {
        switch self {
        case .none, .established: return false
        default: return true
        }
    }

    var displayString: String {
        switch self {
        case .none: return ""
        case .connecting: return CallStatus.connecting
        case .ringingIncoming(name: let name?): return CallStatus.Incoming.user("\(name ?? "")")
        case .ringingIncoming(name: nil): return CallStatus.incoming
        case .ringingOutgoing: return CallStatus.outgoing
        case .established(duration: let duration): return callDurationFormatter.string(from: duration) ?? ""
        case .reconnecting: return CallStatus.reconnecting
        case .terminating: return CallStatus.terminating
        }
    }
}

class EstablishingCallStatusView: UIView {
    private let titleLabel = DynamicFontLabel(text: "",
                                             fontSpec: .largeSemiboldFont,
                                             color: SemanticColors.Label.textDefault)
    private let callStateLabel = DynamicFontLabel(text: L10n.Localizable.Voice.Calling.title,
                                                  fontSpec: .mediumRegularFont,
                                                  color: SemanticColors.Label.textDefault)
    private let securityLevelView = SecurityLevelView()
    private let profileImageView = UIImageView()
    private let stackView = UIStackView(axis: .vertical)

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        [stackView, profileImageView, securityLevelView].prepareForLayout()
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        [titleLabel, callStateLabel, securityLevelView].forEach(stackView.addArrangedSubview)
        addSubview(profileImageView)
        profileImageView.layer.cornerRadius = 64.0
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2.0
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).withPriority(.required),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 6.0).withPriority(.defaultLow),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            securityLevelView.widthAnchor.constraint(equalTo: widthAnchor),

            profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 128.0).withPriority(.defaultHigh - 1.0),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),

            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).withPriority(.defaultLow + 1.0),
            profileImageView.topAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: 16.0).withPriority(.required),
            profileImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20.0).withPriority(.required)

        ])
    }

    func setTitle(title: String) {
        titleLabel.text = title
    }

    func setProfileImage(image: UIImage?) {
        profileImageView.image = image
    }

    func updateState(state: CallStatusViewState) {
        callStateLabel.text = state.displayString
    }

    func setProfileImage(hidden: Bool) {
        profileImageView.isHidden = hidden
    }

    func configureSecurityLevelView(with otherUsers: [UserType]) {
        securityLevelView.configure(with: otherUsers)
    }
}

// MARK: - Helper

private let callDurationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter
}()
