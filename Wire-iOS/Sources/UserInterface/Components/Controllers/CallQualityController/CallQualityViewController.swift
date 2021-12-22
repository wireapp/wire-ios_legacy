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

import Foundation
import UIKit

protocol CallQualityViewControllerDelegate: AnyObject {
    func callQualityControllerDidFinishWithoutScore(_ controller: CallQualityViewController)
    func callQualityController(_ controller: CallQualityViewController, didSelect score: Int)
}

final class CallQualityViewController: UIViewController, UIGestureRecognizerDelegate {

    let questionLabelText: String
    let callDuration: Int

    weak var delegate: CallQualityViewControllerDelegate?

    let contentView = RoundedView()
    let dimmingView = UIView()
    let closeButton = IconButton()
    let titleLabel = UILabel()
    let questionLabel = UILabel()

    var callQualityStackView: CustomSpacingStackView!
    var scoreSelectorView: QualityScoreSelectorView!
    var dismissTapGestureRecognizer: UITapGestureRecognizer!

    // MARK: Contraints

    private var ipad_centerXConstraint: NSLayoutConstraint!
    private var ipad_centerYConstraint: NSLayoutConstraint!
    private var iphone_leadingConstraint: NSLayoutConstraint!
    private var iphone_trailingConstraint: NSLayoutConstraint!
    private var iphone_bottomConstraint: NSLayoutConstraint!
    private var iphone_paddingLeftConstraint: NSLayoutConstraint!
    private var iphone_paddingRightConstraint: NSLayoutConstraint!
    private var ipad_paddingLeftConstraint: NSLayoutConstraint!
    private var ipad_paddingRightConstraint: NSLayoutConstraint!

    // MARK: Initialization

    init(questionLabelText: String, callDuration: Int) {
        self.questionLabelText = questionLabelText
        self.callDuration = callDuration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        createConstraints()
        updateLayout(for: traitCollection)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: Interface

    func createViews() {

        self.scoreSelectorView = QualityScoreSelectorView(onScoreSet: { [weak self] score in
            self?.delegate?.callQualityController(self!, didSelect: score)
        })

        dimmingView.backgroundColor = UIColor.CallQuality.backgroundDim
        dimmingView.alpha = 0

        let graphite = UIColor.from(scheme: .textForeground)
        let closeButtonTitle = "calling.quality_survey.skip_button_title".localized(uppercased: true)
        closeButton.setTitle(closeButtonTitle, for: .normal)
        closeButton.accessibilityIdentifier = "score_close"
        closeButton.accessibilityLabel = closeButtonTitle
        closeButton.titleLabel?.font = FontSpec(.small, .semibold).font!
        closeButton.setTitleColor(graphite, for: .normal)
        closeButton.setTitleColor(graphite.withAlphaComponent(0.6), for: .highlighted)

        closeButton.addTarget(self, action: #selector(onCloseButtonTapped), for: .touchUpInside)

        titleLabel.textColor = UIColor.CallQuality.title
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: UIFont.Weight.medium)
        titleLabel.text = NSLocalizedString("calling.quality_survey.title", comment: "")
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center

        questionLabel.text = questionLabelText
        questionLabel.font = FontSpec(.normal, .regular).font
        questionLabel.textColor = UIColor.CallQuality.question
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0

        callQualityStackView = CustomSpacingStackView(customSpacedArrangedSubviews: [titleLabel, questionLabel, scoreSelectorView, closeButton])
        callQualityStackView.alignment = .fill
        callQualityStackView.distribution = .fill
        callQualityStackView.axis = .vertical
        callQualityStackView.spacing = 10
        callQualityStackView.wr_addCustomSpacing(24, after: titleLabel)
        callQualityStackView.wr_addCustomSpacing(32, after: questionLabel)
        callQualityStackView.wr_addCustomSpacing(12, after: scoreSelectorView)

        dismissTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapToDismiss))
        dismissTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissTapGestureRecognizer)

        contentView.shape = .rounded(radius: 32)
        contentView.backgroundColor = UIColor.CallQuality.contentBackground

        view.addSubview(dimmingView)
        view.addSubview(contentView)
        contentView.addSubview(callQualityStackView)

    }

    private func createConstraints() {
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        callQualityStackView.translatesAutoresizingMaskIntoConstraints = false

        // Core constraints
        let coreConstraints = [
            // Dimming view
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content stack
            callQualityStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            callQualityStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            // Content view
            contentView.topAnchor.constraint(equalTo: callQualityStackView.topAnchor, constant: -44)
        ]

        NSLayoutConstraint.activate(coreConstraints)

        // Adaptive Constraints

        iphone_leadingConstraint = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8)
        iphone_trailingConstraint = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)

        let bottomAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> = view.safeAreaLayoutGuide.bottomAnchor

        iphone_bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ipad_centerYConstraint = contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ipad_centerXConstraint = contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor)

        iphone_paddingLeftConstraint = callQualityStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        iphone_paddingRightConstraint = callQualityStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ipad_paddingLeftConstraint = callQualityStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 44)
        ipad_paddingRightConstraint = callQualityStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -44)
    }

    // MARK: Dismiss Events

    @objc func onCloseButtonTapped() {
        delegate?.callQualityControllerDidFinishWithoutScore(self)
    }

    @objc func onTapToDismiss() {
        delegate?.callQualityControllerDidFinishWithoutScore(self)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view?.isDescendant(of: contentView) == false
    }

    override func accessibilityPerformMagicTap() -> Bool {
        onTapToDismiss()
        return true
    }

    // MARK: Adaptive Layout

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in self.updateLayout(for: newCollection) })
    }

    func updateLayout(isRegular: Bool) {
        ipad_centerYConstraint.isActive = isRegular
        ipad_centerXConstraint.isActive = isRegular
        iphone_leadingConstraint.isActive = !isRegular
        iphone_trailingConstraint.isActive = !isRegular
        iphone_bottomConstraint.isActive = !isRegular
        iphone_paddingLeftConstraint.isActive = !isRegular
        iphone_paddingRightConstraint.isActive = !isRegular
        ipad_paddingLeftConstraint.isActive = isRegular
        ipad_paddingRightConstraint.isActive = isRegular
    }

    func updateLayout(for traitCollection: UITraitCollection) {
        updateLayout(isRegular: traitCollection.horizontalSizeClass == .regular)
    }

}

final class CallQualityView: UIStackView {
    let scoreLabel = UILabel()
    let scoreButton = Button()
    let callback: (Int) -> Void
    let labelText: String
    let buttonScore: Int

    init(labelText: String, buttonScore: Int, callback: @escaping (Int) -> Void) {
        self.callback = callback
        self.buttonScore = buttonScore
        self.labelText = labelText

        super.init(frame: .zero)

        axis = .vertical
        spacing = 16

        scoreLabel.text = [1, 3, 5].contains(buttonScore) ? labelText : ""
        scoreLabel.font = FontSpec(.medium, .regular).font
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor.CallQuality.score
        scoreLabel.adjustsFontSizeToFitWidth = true

        scoreButton.tag = buttonScore
        scoreButton.circular = true
        scoreButton.setTitle(String(buttonScore), for: .normal)
        scoreButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: UIFont.Weight.regular)
        scoreButton.setTitleColor(UIColor.CallQuality.score, for: .normal)
        scoreButton.setTitleColor(.white, for: .highlighted)
        scoreButton.setTitleColor(.white, for: .selected)
        scoreButton.addTarget(self, action: #selector(onClick), for: .primaryActionTriggered)
        scoreButton.setBackgroundImageColor(UIColor.CallQuality.scoreBackground, for: .normal)
        scoreButton.setBackgroundImageColor(UIColor.CallQuality.scoreHighlight, for: .highlighted)
        scoreButton.setBackgroundImageColor(UIColor.CallQuality.scoreHighlight, for: .selected)
        scoreButton.accessibilityIdentifier = "score_\(buttonScore)"

        scoreButton.accessibilityLabel = labelText

        addArrangedSubview(scoreLabel)
        addArrangedSubview(scoreButton)

        createConstraints()
    }

    private func createConstraints() {
        scoreButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreButton.widthAnchor.constraint(lessThanOrEqualToConstant: 48),
            scoreButton.heightAnchor.constraint(equalTo: scoreButton.widthAnchor)
        ])
    }

    @available(*, unavailable)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onClick(_ sender: UIButton) {
        callback(buttonScore)
    }
}

class QualityScoreSelectorView: UIView {
    private let scoreStackView = UIStackView()

    weak var delegate: CallQualityViewControllerDelegate?

    public let onScoreSet: ((Int) -> Void)

    init(onScoreSet: @escaping (Int) -> Void) {
        self.onScoreSet = onScoreSet
        super.init(frame: .zero)

        scoreStackView.axis = .horizontal
        scoreStackView.distribution = .fillEqually
        scoreStackView.spacing = 12

        (1 ... 5)
            .map { (localizedNameForScore($0), $0) }
            .map { CallQualityView(labelText: $0.0, buttonScore: $0.1, callback: onScoreSet) }
            .forEach(scoreStackView.addArrangedSubview)

        addSubview(scoreStackView)
        scoreStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          scoreStackView.topAnchor.constraint(equalTo: topAnchor),
          scoreStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
          scoreStackView.leftAnchor.constraint(equalTo: leftAnchor),
          scoreStackView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }

    override func layoutSubviews() {

        if traitCollection.horizontalSizeClass == .regular {
            scoreStackView.spacing = 24
        } else if let superviewWidth = superview?.frame.size.width {
            scoreStackView.spacing = superviewWidth >= CGFloat(350) ? 24 : 12
        } else {
            scoreStackView.spacing = 12
        }

    }

    func localizedNameForScore(_ score: Int) -> String {
        return NSLocalizedString("calling.quality_survey.answer.\(score)", comment: "")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CallQualityAnimator: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (presented is CallQualityViewController) ? CallQualityPresentationTransition() : nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return (dismissed is CallQualityViewController) ? CallQualityDismissalTransition() : nil
    }
}
