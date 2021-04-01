//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

class NotificationLabel: UIView {

    private var timer: Timer?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let messageLabel = UILabel(
        key: nil,
        size: .medium,
        weight: .semibold,
        color: .textForeground,
        variant: .dark
    )

    // MARK: - View Life Cycle

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        layer.cornerRadius = 12
        blurView.layer.cornerRadius = 12

        messageLabel.numberOfLines = 0

        [blurView, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.clipsToBounds = true
            addSubview($0)
        }
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    // MARK: - Public Interface

    func show(message: String, hideAfter timeInterval: TimeInterval? = nil) {
        messageLabel.text = message
        createTimer(with: timeInterval)
        animateMessage(show: true)
        startTimer()
    }

    func hide() {
        stopTimer()
        animateMessage(show: false)
    }

    // MARK: - Helpers

    private func animateMessage(show: Bool) {
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.alpha = show ? 1 : 0
        }
    }

    private func createTimer(with timeInterval: TimeInterval?) {
        guard let timeInterval = timeInterval else { return }

        timer = Timer(timeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.animateMessage(show: false)
        }
    }

    private func startTimer() {
        timer?.fire()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
