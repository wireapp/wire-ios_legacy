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

final class CallStatusView: UIView {
    
    struct Configuration {
        enum CallType {
            case audio, video
        }
        
        enum State {
            case connecting
            case ringingIncoming(name: String) // Caller name + call type "XYZ is (video) calling..."
            case ringingOutgoing // "Ringing..."
            case established(duration: TimeInterval) // Call duration in seconds "04:18"
            case reconnecting // "Reconnecting..."
            case terminating // "Ending call..."
        }
        
        var state: State
        var type: CallType
        var variant: ColorSchemeVariant
        let title: String
    }
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stackView = UIStackView(axis: .vertical)
    
    var configuration: Configuration {
        didSet {
            updateConfiguration()
        }
    }
    
    init(configuration: Configuration) {
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
        addSubview(stackView)
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 12
        [titleLabel, subtitleLabel].forEach {
            stackView.addArrangedSubview($0)
            $0.textAlignment = .center
        }
        
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightSemibold)
        subtitleLabel.font = FontSpec(.normal, .semibold).font
        subtitleLabel.alpha = 0.64
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func updateConfiguration() {
        titleLabel.text = configuration.title
        subtitleLabel.text = configuration.displayString
        [titleLabel, subtitleLabel].forEach {
            $0.textColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: configuration.effectiveColorVariant)
        }
    }
    
}

// MARK: - Helper

fileprivate extension CallStatusView.Configuration {
    
    private static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = DateComponentsFormatter.ZeroFormattingBehavior(rawValue: 0)
        return formatter
    }()
    
    var displayString: String {
        switch state {
        case .connecting: return "call.status.connecting".localized
        case .ringingIncoming(name: let name) where type == .audio: return "call.status.incoming.audio".localized(args: name)
        case .ringingIncoming(name: let name): return "call.status.incoming.video".localized(args: name)
        case .ringingOutgoing: return "call.status.outgoing".localized
        case .established(duration: let duration): return CallStatusView.Configuration.formatter.string(from: duration) ?? ""
        case .reconnecting: return "call.status.reconnecting".localized
        case .terminating: return "call.status.terminating".localized
        }
    }
    
    var effectiveColorVariant: ColorSchemeVariant {
        guard type == .audio else { return .dark }
        return variant == .dark ? .dark : .light
    }
    
}
