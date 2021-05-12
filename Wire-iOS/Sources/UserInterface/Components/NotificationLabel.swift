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

    private(set) var timer: Timer?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let messageLabel = UILabel(
        key: nil,
        size: .medium,
        weight: .semibold,
        color: .textForeground,
        variant: .dark
    )

    /// use to disable animations for unit tests
    private var shouldAnimate: Bool

    // MARK: - View Life Cycle

    init(shouldAnimate: Bool = true) {
        self.shouldAnimate = shouldAnimate
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
        isHidden = true
        layer.cornerRadius = 12
        blurView.layer.cornerRadius = 12

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

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

    /// Shows a message with an optional timer.
    /// - Parameters:
    ///   - message: message to show
    ///   - timeInterval: optional time interval after which the message will be hidden
    func show(message: String, hideAfter timeInterval: TimeInterval? = nil) {
        messageLabel.text = message
        animateMessage(show: true) { [weak self] in
            self?.startTimer(with: timeInterval)
        }
    }

    /// Hides message and invalidates the timer.
    func hideAndStopTimer() {
        timer?.invalidate()
        animateMessage(show: false)
    }

    /// Changes visibility of the message label.
    /// No effect if the message has already been hidden after the timer was invalidated.
    /// - Parameter hidden: wether or not the message should be hidden
    func setMessageHidden(_ hidden: Bool) {
        // only change visibility if timer isn't invalid
        guard timer == nil || timer?.isValid == true else {
            return
        }

        animateMessage(show: !hidden)
    }

    // MARK: - Helpers

    private func animateMessage(show: Bool, completion: (() -> Void)? = nil) {
        if show { isHidden = false }

        let animationBlock: () -> Void = { [weak self] in
            self?.alpha = show ? 1 : 0
        }

        let completionBlock: (Bool) -> Void = { [weak self] _ in
            self?.isHidden = !show
            completion?()
        }

        if shouldAnimate {
            UIView.animate(withDuration: 0.5, animations: animationBlock, completion: completionBlock)
        } else {
            animationBlock()
            completionBlock(true)
        }
    }

    private func startTimer(with timeInterval: TimeInterval?) {
        guard let timeInterval = timeInterval else { return }

        timer = .scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.animateMessage(show: false)
        }
    }
}
