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

import AVKit

protocol CallActionThemable: class {
    var appearance: CallActionAppearance { get set }
}

@available(iOS 11, *)
final class RoutePickerButton: UIView, CallActionThemable {
    private let routePickerView = AVRoutePickerView()
    private let subtitleLabel = UILabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let backgroundView = UIView()
    
    var appearance: CallActionAppearance = .dark(blurred: false) {
        didSet {
            updateState()
        }
    }
    
    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [backgroundView, blurView, routePickerView, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 32
        blurView.isUserInteractionEnabled = false
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 32
        routePickerView.layer.cornerRadius = 32
        routePickerView.layer.masksToBounds = true
        subtitleLabel.textAlignment = .center
        subtitleLabel.textTransform = .upper
        subtitleLabel.text = "voice.airplay_button.title".localized
        subtitleLabel.font = FontSpec(.small, .semibold).font
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 64),
            heightAnchor.constraint(equalToConstant: 88),
            blurView.centerXAnchor.constraint(equalTo: centerXAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.heightAnchor.constraint(equalToConstant: 64),
            blurView.widthAnchor.constraint(equalToConstant: 64),
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.heightAnchor.constraint(equalToConstant: 64),
            backgroundView.widthAnchor.constraint(equalToConstant: 64),
            routePickerView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
            routePickerView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            routePickerView.heightAnchor.constraint(equalToConstant: 36),
            routePickerView.widthAnchor.constraint(equalToConstant: 36),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func updateState() {
        subtitleLabel.textColor = appearance.iconColorNormal
        routePickerView.backgroundColor = .clear
        backgroundView.backgroundColor = appearance.backgroundColorNormal
        routePickerView.tintColor = appearance.iconColorNormal
        routePickerView.activeTintColor = appearance.iconColorNormal
        blurView.isHidden = !appearance.showBlur
        backgroundView.isHidden = appearance.showBlur
    }
}
