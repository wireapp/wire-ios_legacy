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
import WireExtensionComponents

protocol CallStatusViewInputType: CallTypeProvider, ColorVariantProvider {
    var state: CallStatusViewState { get }
    var isConstantBitRate: Bool { get }
    var title: String { get }
}

protocol CallTypeProvider {
    var isVideoCall: Bool { get }
}

protocol ColorVariantProvider {
    var variant: ColorSchemeVariant { get }
}

extension CallStatusViewInputType {
    var overlayBackgroundColor: UIColor {
        switch (isVideoCall, state) {
        case (false, _): return variant == .light ? UIColor(scheme: .background, variant: .light) : .black
        case (true, .ringingOutgoing), (true, .ringingIncoming): return UIColor.black.withAlphaComponent(0.4)
        case (true, _): return UIColor.black.withAlphaComponent(0.64)
        }
    }
}

enum CallStatusViewState {
    case none
    case connecting
    case ringingIncoming(name: String?) // Caller name + call type "XYZ is calling..."
    case ringingOutgoing // "Ringing..."
    case established(duration: TimeInterval) // Call duration in seconds "04:18"
    case reconnecting // "Reconnecting..."
    case terminating // "Ending call..."
}

extension CallStatusViewState: Equatable {
    
    static func ==(lhs: CallStatusViewState, rhs: CallStatusViewState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.connecting, .connecting), (.reconnecting, .reconnecting), (.terminating, .terminating), (.ringingOutgoing, .ringingOutgoing):
            return true
        case (.ringingIncoming(let lhsName), .ringingIncoming(let rhsName)):
            return lhsName == rhsName
        case (.established(let lhsDuration), .established(let rhsDuration)):
            return lhsDuration == rhsDuration
        default:
            return false
        }
    }
    
}

final class CallStatusView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let bitrateLabel = UILabel()
    private let stackView = UIStackView(axis: .vertical)
    
    var configuration: CallStatusViewInputType {
        didSet {
            updateConfiguration()
        }
    }
    
    init(configuration: CallStatusViewInputType) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        updateConfiguration()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [stackView, bitrateLabel].forEach(addSubview)
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        bitrateLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 12
        accessibilityIdentifier = "CallStatusLabel"
        [titleLabel, subtitleLabel].forEach(stackView.addArrangedSubview)
        [titleLabel, subtitleLabel, bitrateLabel].forEach {
            $0.textAlignment = .center
        }

        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = .systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        subtitleLabel.font = FontSpec(.normal, .semibold).font
        subtitleLabel.alpha = 0.64

        bitrateLabel.text = "call.status.constant_bitrate".localized.uppercased()
        bitrateLabel.font = FontSpec(.small, .semibold).font
        bitrateLabel.alpha = 0.64
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            bitrateLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            bitrateLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bitrateLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bitrateLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func updateConfiguration() {
        titleLabel.text = configuration.title
        subtitleLabel.text = configuration.displayString
        bitrateLabel.isHidden = !configuration.isConstantBitRate

        [titleLabel, subtitleLabel, bitrateLabel].forEach {
            $0.textColor = UIColor(scheme: .textForeground, variant: configuration.effectiveColorVariant)
        }

        accessibilityLabel = stackView.arrangedSubviews.compactMap { $0.accessibilityLabel }.joined(separator: "\n")
    }
    
}

// MARK: - Helper

private let callDurationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter
}()

extension CallStatusViewInputType {

    var displayString: String {
        switch state {
        case .none: return ""
        case .connecting: return "call.status.connecting".localized
        case .ringingIncoming(name: let name?): return "call.status.incoming.user".localized(args: name)
        case .ringingIncoming(name: nil): return "call.status.incoming".localized
        case .ringingOutgoing: return "call.status.outgoing".localized
        case .established(duration: let duration): return callDurationFormatter.string(from: duration) ?? ""
        case .reconnecting: return "call.status.reconnecting".localized
        case .terminating: return "call.status.terminating".localized
        }
    }
    
    var effectiveColorVariant: ColorSchemeVariant {
        guard !isVideoCall else { return .dark }
        return variant == .dark ? .dark : .light
    }
    
}
