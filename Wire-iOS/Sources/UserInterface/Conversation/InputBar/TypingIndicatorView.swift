//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

final class AnimatedPenView: UIView {

    private let WritingAnimationKey = "writing"
    private let dots = UIImageView()
    private let pen = UIImageView()

    var isAnimating: Bool = false {
        didSet {
            pen.layer.speed = isAnimating ? 1 : 0
            pen.layer.beginTime = pen.layer.convertTime(CACurrentMediaTime(), from: nil)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let iconColor = SemanticColors.Icon.foregroundDefault
        let backgroundColor = SemanticColors.View.backgroundConversationView

        dots.setIcon(.typingDots, size: 8, color: iconColor)
        pen.setIcon(.pencil, size: 8, color: iconColor)
        pen.backgroundColor = backgroundColor
        pen.contentMode = .center

        addSubview(dots)
        addSubview(pen)

        setupConstraints()
        startWritingAnimation()

        pen.layer.speed = 0
        pen.layer.timeOffset = 2

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        startWritingAnimation()
    }

    private func setupConstraints() {
        [dots,
         pen].prepareForLayout()

        let distributeConstraint = pen.leftAnchor.constraint(equalTo: dots.rightAnchor, constant: 2)

        // Lower the priority to prevent this breaks when TypingIndicatorView's width = 0
        distributeConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            distributeConstraint,

            dots.leftAnchor.constraint(equalTo: leftAnchor),
            dots.topAnchor.constraint(equalTo: topAnchor),
            dots.bottomAnchor.constraint(equalTo: bottomAnchor),

            pen.rightAnchor.constraint(equalTo: rightAnchor),
            pen.topAnchor.constraint(equalTo: topAnchor),
            pen.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func startWritingAnimation() {
        let p1 = 7
        let p2 = 10
        let p3 = 13
        let moveX = CAKeyframeAnimation(keyPath: "position.x")
        moveX.values = [p1, p2, p2, p3, p3, p1]
        moveX.keyTimes = [0, 0.25, 0.35, 0.50, 0.75, 0.85]
        moveX.duration = 2
        moveX.repeatCount = Float.infinity

        pen.layer.add(moveX, forKey: WritingAnimationKey)
    }

    func stopWritingAnimation() {
        pen.layer.removeAnimation(forKey: WritingAnimationKey)
    }

    @objc func applicationDidBecomeActive(_ notification: Notification) {
        startWritingAnimation()
    }

}

final class TypingIndicatorView: UIView {

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont
        label.textColor = SemanticColors.Label.textDefault

        return label
    }()
    let animatedPen = AnimatedPenView()
    let container: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundConversationView

        return view
    }()
    let expandingLine: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundConversationView

        return view
    }()

    private lazy var expandingLineWidth: NSLayoutConstraint = expandingLine.widthAnchor.constraint(equalToConstant: 0)

    var typingUsers: [UserType] = [] {
        didSet {
            updateNameLabel()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(expandingLine)
        addSubview(container)
        container.addSubview(nameLabel)
        container.addSubview(animatedPen)

        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        container.layer.cornerRadius = container.bounds.size.height / 2
    }

    private func setupConstraints() {
        [nameLabel,
         container,
         animatedPen,
         expandingLine].prepareForLayout()

        // Lower the priority to prevent this breaks when container's height = 0
        let nameLabelBottomConstraint = container.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4)

        nameLabelBottomConstraint.priority = .defaultHigh

        let distributeConstraint = nameLabel.leftAnchor.constraint(equalTo: animatedPen.rightAnchor, constant: 4)

        distributeConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leftAnchor.constraint(equalTo: leftAnchor),
            container.rightAnchor.constraint(equalTo: rightAnchor),

            distributeConstraint,
            animatedPen.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 8),
            animatedPen.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            nameLabelBottomConstraint,
            nameLabel.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -8),

            expandingLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            expandingLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            expandingLine.heightAnchor.constraint(equalToConstant: 1),
            expandingLineWidth
        ])
    }

    func updateNameLabel() {
        nameLabel.text = typingUsers.compactMap { $0.name?.uppercased(with: Locale.current) }.joined(separator: ", ")
    }

    func setHidden(_ hidden: Bool, animated: Bool, completion: Completion? = nil) {

        let collapseLine = { () -> Void in
            self.expandingLineWidth.constant = 0
            self.layoutIfNeeded()
        }

        let expandLine = { () -> Void in
            self.expandingLineWidth.constant = self.bounds.width
            self.layoutIfNeeded()
        }

        let showContainer = {
            self.container.alpha = 1
        }

        let hideContainer = {
            self.container.alpha = 0
        }

        if animated {
            if hidden {
                collapseLine()
                UIView.animate(withDuration: 0.15, animations: hideContainer) { _ in
                    completion?()
                }
            } else {
                animatedPen.isAnimating = false
                self.layoutSubviews()
                UIView.animate(easing: .easeInOutQuad, duration: 0.35, animations: expandLine)
                UIView.animate(easing: .easeInQuad,
                               duration: 0.15,
                               delayTime: 0.15,
                               animations: showContainer, completion: { _ in
                                self.animatedPen.isAnimating = true
                                completion?()
                               })
            }

        } else {
            if hidden {
                collapseLine()
                self.container.alpha = 0
            } else {
                expandLine()
                showContainer()
            }
            completion?()
        }
    }

}
