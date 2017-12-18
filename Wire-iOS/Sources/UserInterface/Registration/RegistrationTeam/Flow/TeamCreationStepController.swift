//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography

final class TeamCreationStepController: UIViewController {

    /// headline font size is fixed and not affected by dynamic type setting,
    static let headlineFont         = UIFont.systemFont(ofSize: 40, weight: UIFontWeightLight)
    /// For 320 pt width screen
    static let headlineSmallFont    = UIFont.systemFont(ofSize: 32, weight: UIFontWeightLight)
    static let subtextFont          = FontSpec(.normal, .regular).font!
    static let errorFont            = FontSpec(.small, .semibold).font!
    static let textButtonFont       = FontSpec(.small, .semibold).font!

    static let mainViewHeight: CGFloat = 56

    let stepDescription: TeamCreationStepDescription

    private var headlineLabel: UILabel!
    private var subtextLabel: UILabel!
    fileprivate var errorLabel: UILabel!

    fileprivate var secondaryViewsStackView: UIStackView!
    fileprivate var errorViewContainer: UIView!
    private var mainViewContainer: UIView!
    private var topSpacer: UIView!
    private var bottomSpacer: UIView!

    private var backButton: UIView?

    /// mainView is a textField or CharacterInputField in team creation screens
    private var mainView: UIView!
    private var secondaryViews: [UIView] = []
    fileprivate var secondaryErrorView: UIView?

    private var mainViewWidthRegular: NSLayoutConstraint!
    private var mainViewWidthCompact: NSLayoutConstraint!
    private var topSpacerHeight: NSLayoutConstraint!
    private var bottomSpacerHeight: NSLayoutConstraint!
    private var spacerEqualHeight: NSLayoutConstraint!

    init(description: TeamCreationStepDescription) {
        self.stepDescription = description
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var showLoadingView: Bool {
        didSet {
            stepDescription.mainView.acceptsInput = !showLoadingView
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Team.background

        createViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeKeyboard()
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        mainView.becomeFirstResponder()

        updateKeyboardOffset(keyboardFrame: KeyboardFrameObserver.shared().keyboardFrame())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        NotificationCenter.default.removeObserver(self)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateMainViewWidthConstraint()
        updateHeadlineLabelFont()
    }

    // MARK: - Keyboard shown/hide

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }

    func updateKeyboardOffset(keyboardFrame: CGRect) {
        let keyboardHeight = keyboardFrame.height

        spacerEqualHeight.constant = self.view.frame.size.height - keyboardFrame.origin.y
        bottomSpacerHeight.constant = 24 + keyboardHeight

        UIView.performWithoutAnimation {
            self.view.setNeedsLayout()
        }
    }

    dynamic func keyboardWillShow(_ notification: Notification) {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            break
        default:
            spacerEqualHeight.isActive = false
            topSpacerHeight.isActive = true
            bottomSpacerHeight.isActive = true
        }

        animateViewsToAccomodateKeyboard(with: notification)
    }

    dynamic func keyboardWillHide(_ notification: Notification) {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            break
        default:
            topSpacerHeight.isActive = false
            bottomSpacerHeight.isActive = false
            spacerEqualHeight.isActive = true
        }

        animateViewsToAccomodateKeyboard(with: notification)
    }

    dynamic func keyboardWillChangeFrame(_ notification: Notification) {
        animateViewsToAccomodateKeyboard(with: notification)
    }

    func animateViewsToAccomodateKeyboard(with notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {

            updateKeyboardOffset(keyboardFrame: keyboardFrame.cgRectValue)
        }
    }

    // MARK: - View creation

    fileprivate func updateHeadlineLabelFont() {
        headlineLabel.font = self.view.frame.size.width > 320 ? TeamCreationStepController.headlineFont : TeamCreationStepController.headlineSmallFont
    }

    private func createViews() {
        backButton = stepDescription.backButton?.create()

        headlineLabel = UILabel()
        headlineLabel.textAlignment = .center
        headlineLabel.textColor = UIColor.Team.textColor
        headlineLabel.text = stepDescription.headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        updateHeadlineLabelFont()

        subtextLabel = UILabel()
        subtextLabel.textAlignment = .center
        subtextLabel.text = stepDescription.subtext
        subtextLabel.font = TeamCreationStepController.subtextFont
        subtextLabel.textColor = UIColor.Team.subtitleColor
        subtextLabel.numberOfLines = 0
        subtextLabel.lineBreakMode = .byWordWrapping
        subtextLabel.translatesAutoresizingMaskIntoConstraints = false

        mainViewContainer = UIView()
        mainViewContainer.translatesAutoresizingMaskIntoConstraints = false

        topSpacer = UIView()
        bottomSpacer = UIView()

        [topSpacer, bottomSpacer].forEach() { view in
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        mainView = stepDescription.mainView.create()
        mainViewContainer.addSubview(mainView)

        errorViewContainer = UIView()
        errorViewContainer.translatesAutoresizingMaskIntoConstraints = false

        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.font = TeamCreationStepController.errorFont
        errorLabel.textColor = UIColor.Team.errorMessageColor
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorViewContainer.addSubview(errorLabel)

        if let secondaryView = stepDescription.secondaryView {
            secondaryViews = secondaryView.views.map { $0.create() }
        }

        secondaryViewsStackView = UIStackView(arrangedSubviews: secondaryViews)
        secondaryViewsStackView.distribution = .equalCentering
        secondaryViewsStackView.spacing = 24
        secondaryViewsStackView.translatesAutoresizingMaskIntoConstraints = false

        [topSpacer,
         bottomSpacer,
         backButton,
         headlineLabel,
         subtextLabel,
         mainViewContainer,
         errorViewContainer,
         secondaryViewsStackView].flatMap {$0}.forEach {
            self.view.addSubview($0)
        }
    }

    fileprivate func updateMainViewWidthConstraint() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            mainViewWidthRegular.isActive = false
            mainViewWidthCompact.isActive = true
        default:
            mainViewWidthCompact.isActive = false
            mainViewWidthRegular.isActive = true
        }
    }

    private func createConstraints() {
        if let backButton = backButton {

            var backButtonTopMargin: CGFloat
            if #available(iOS 11.0, *) {
                backButtonTopMargin = 12
            } else {
                backButtonTopMargin = 32
            }

            let backButtonSize = UIImage.size(for: .tiny)

            constrain(view, backButton, headlineLabel) { view, backButton, headlineLabel in
                backButton.leading == view.leading + 16
                backButton.top == view.topMargin + backButtonTopMargin
                backButton.height == backButtonSize
                backButton.height == backButton.width

                headlineLabel.top >= backButton.bottomMargin + 20
            }
        }

        let keyboardHeight = KeyboardFrameObserver.shared().keyboardFrame().height

        constrain(view, topSpacer, bottomSpacer) { view, topSpacer, bottomSpacer in
            spacerEqualHeight = bottomSpacer.height == topSpacer.height + keyboardHeight

            topSpacerHeight = topSpacer.height >= 24
            bottomSpacerHeight = bottomSpacer.height == 24 + keyboardHeight

            topSpacer.centerX == view.centerX
            bottomSpacer.centerX == view.centerX
            topSpacer.width == view.width
            bottomSpacer.width == view.width
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            topSpacerHeight.isActive = false
            bottomSpacerHeight.isActive = false
        } else {
            spacerEqualHeight.isActive = false
        }

        constrain(view, secondaryViewsStackView, errorViewContainer, mainViewContainer, bottomSpacer) { view, secondaryViewsStackView, errorViewContainer, mainViewContainer, bottomSpacer in

            secondaryViewsStackView.bottom == bottomSpacer.top
            bottomSpacer.bottom == view.bottom

            secondaryViewsStackView.leading >= view.leading
            secondaryViewsStackView.trailing <= view.trailing
            secondaryViewsStackView.height == 42 ~ LayoutPriority(500)
            secondaryViewsStackView.height >= 13
            secondaryViewsStackView.centerX == view.centerX

            errorViewContainer.bottom == secondaryViewsStackView.top
            errorViewContainer.leading == view.leading
            errorViewContainer.trailing == view.trailing
            errorViewContainer.height == 30

            mainViewContainer.bottom == errorViewContainer.top

            mainViewContainer.centerX == view.centerX

            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                mainViewWidthRegular = mainViewContainer.width == 375
                mainViewWidthCompact = mainViewContainer.width == view.width
            default:
                mainViewContainer.width == view.width
            }

        }

        constrain(view, mainViewContainer, subtextLabel, headlineLabel, topSpacer) { view, inputViewsContainer, subtextLabel, headlineLabel, topSpacer in

            topSpacer.top == view.top
            headlineLabel.top == topSpacer.bottom

            headlineLabel.bottom == subtextLabel.top - 24 ~ LayoutPriority(750)
            headlineLabel.leading == view.leadingMargin
            headlineLabel.trailing == view.trailingMargin

            subtextLabel.top >= headlineLabel.bottom + 5
            subtextLabel.leading == view.leadingMargin
            subtextLabel.trailing == view.trailingMargin
            subtextLabel.height >= 19

            inputViewsContainer.top >= subtextLabel.bottom + 5
            inputViewsContainer.top == subtextLabel.bottom + 80 ~ LayoutPriority(800)
        }

        constrain(mainViewContainer, mainView) { mainViewContainer, mainView in
            mainView.height == TeamCreationStepController.mainViewHeight

            mainView.top == mainViewContainer.top
            mainView.leading == mainViewContainer.leading
            mainView.trailing == mainViewContainer.trailing
            mainView.bottom == mainViewContainer.bottom
        }

        constrain(errorViewContainer, errorLabel) { errorViewContainer, errorLabel in
            errorLabel.centerY == errorViewContainer.centerY
            errorLabel.leading == errorViewContainer.leadingMargin
            errorLabel.trailing == errorViewContainer.trailingMargin
            errorLabel.topMargin == errorViewContainer.topMargin
            errorLabel.bottomMargin == errorViewContainer.bottomMargin
            errorLabel.height >= 19
        }

        headlineLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        subtextLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        updateMainViewWidthConstraint()
    }
}

// MARK: - Error handling
extension TeamCreationStepController {
    func clearError() {
        errorLabel.text = nil
        showSecondaryView(for: nil)
        self.errorViewContainer.setNeedsLayout()
    }

    func displayError(_ error: Error) {
        errorLabel.text = error.localizedDescription.uppercased()
        showSecondaryView(for: error)
        self.errorViewContainer.setNeedsLayout()
    }

    func showSecondaryView(for error: Error?) {
        if let view = self.secondaryErrorView {
            secondaryViewsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
            secondaryViewsStackView.arrangedSubviews.forEach { $0.isHidden = false }
            self.secondaryErrorView = nil
        }

        if let error = error, let errorDescription = stepDescription.secondaryView?.display(on: error) {
            let view = errorDescription.create()
            self.secondaryErrorView = view
            secondaryViewsStackView.arrangedSubviews.forEach { $0.isHidden = true }
            secondaryViewsStackView.addArrangedSubview(view)
        }
    }

}
