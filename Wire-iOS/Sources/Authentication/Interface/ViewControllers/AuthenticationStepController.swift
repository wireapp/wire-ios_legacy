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
import WireCommonComponents

/**
 * A view controller that can display the interface from an authentication step.
 */

class AuthenticationStepController: AuthenticationStepViewController {

    /// The step to display.
    let stepDescription: AuthenticationStepDescription

    /// The object that coordinates authentication.
    weak var authenticationCoordinator: AuthenticationCoordinator? {
        didSet {
            stepDescription.secondaryView?.actioner = authenticationCoordinator
            stepDescription.footerView?.actioner = authenticationCoordinator
        }
    }

    // MARK: - Configuration

    static let mainViewHeight: CGFloat = 56

    static let headlineFont         = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.light)
    static let headlineSmallFont    = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight.light)
    static let subtextFont          = FontSpec(.normal, .regular).font!
    static let errorMessageFont     = FontSpec(.medium, .regular).font!
    static let textButtonFont       = FontSpec(.small, .semibold).font!

    // MARK: - Views

    private var contentStack: CustomSpacingStackView!

    private var headlineLabel: DynamicFontLabel!
    private var headlineLabelContainer: ContentInsetView!
    private var subtextLabel: UILabel!
    private var subtextLabelContainer: ContentInsetView!
    private var mainView: UIView!
    fileprivate var errorLabel: UILabel!
    fileprivate var errorLabelContainer: ContentInsetView!

    fileprivate var secondaryViews: [UIView] = []
    fileprivate var footerViews: [UIView] = []
    fileprivate var secondaryErrorView: UIView?
    fileprivate var secondaryViewsStackView: UIStackView!
    fileprivate var footerViewStackView: UIStackView!

    private var mainViewWidthRegular: NSLayoutConstraint!
    private var mainViewWidthCompact: NSLayoutConstraint!
    private var contentCenter: NSLayoutConstraint!
    private var contentCenterConstraintActivation: Bool
    private var rightItemAction: AuthenticationCoordinatorAction?

    var contentCenterYAnchor: NSLayoutYAxisAnchor {
        return contentStack.centerYAnchor
    }

    // MARK: - Initialization

    /**
     * Creates the view controller to display the specified interface description.
     * - parameter description: The description of the step interface.
     */

    required init(description: AuthenticationStepDescription, contentCenterConstraintActivation: Bool = true) {
        self.stepDescription = description
        self.contentCenterConstraintActivation = contentCenterConstraintActivation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SemanticColors.View.backgroundDefault
        createViews()
        createConstraints()
        updateBackButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureObservers()
        showKeyboard()
        UIAccessibility.post(notification: .screenChanged, argument: headlineLabel)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateConstraints(forRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

    // MARK: - View Creation

    /**
     * Creates the main input view for the view controller. Override this method if you need a different
     * main view than the one provided by the step description, or to customize its behavior.
     * - returns: The main view to include in the stack.
     */

    /// Override this method to provide a different main view.
    func createMainView() -> UIView {
        return stepDescription.mainView.create()
    }

    private func createViews() {
        let textPadding = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        let labelColor = SemanticColors.Label.textDefault

        headlineLabel = DynamicFontLabel(fontSpec: .largeLightWithTextStyleFont,
                                         color: labelColor)
        headlineLabelContainer = ContentInsetView(headlineLabel, inset: textPadding)
        headlineLabel.textAlignment = .center
        headlineLabel.text = stepDescription.headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.numberOfLines = 0
        headlineLabel.lineBreakMode = .byWordWrapping
        headlineLabel.accessibilityTraits.insert(.header)

        if stepDescription.subtext != nil {
            subtextLabel = DynamicFontLabel(fontSpec: .normalRegularFont,
                                            color: labelColor)
            subtextLabelContainer = ContentInsetView(subtextLabel, inset: textPadding)
            subtextLabel.textAlignment = .center
            subtextLabel.text = stepDescription.subtext
            subtextLabel.font = AuthenticationStepController.subtextFont
            subtextLabel.numberOfLines = 0
            subtextLabel.lineBreakMode = .byWordWrapping
            subtextLabelContainer.isHidden = stepDescription.subtext == nil
        }

        errorLabel = UILabel()
        let errorInsets = UIEdgeInsets(top: 0, left: 31, bottom: 0, right: 31)
        errorLabelContainer = ContentInsetView(errorLabel, inset: errorInsets)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.font = AuthenticationStepController.errorMessageFont
        errorLabel.textColor = SemanticColors.Label.textErrorDefault
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        updateValidation(initialValidation)

        mainView = createMainView()

        if let secondaryView = stepDescription.secondaryView {
            secondaryViews = secondaryView.views.map { $0.create() }
        }

        if let footerView = stepDescription.footerView {
            footerViews = footerView.views.map { $0.create() }
        }

        secondaryViewsStackView = UIStackView(arrangedSubviews: secondaryViews)
        secondaryViewsStackView.axis = .vertical
        secondaryViewsStackView.distribution = .equalCentering
        secondaryViewsStackView.spacing = 24
        secondaryViewsStackView.translatesAutoresizingMaskIntoConstraints = false

        footerViewStackView = UIStackView(arrangedSubviews: footerViews)
        footerViewStackView.distribution = .equalCentering
        footerViewStackView.axis = .vertical
        footerViewStackView.spacing = 26
        footerViewStackView.translatesAutoresizingMaskIntoConstraints = false

        let subviews = [headlineLabelContainer, subtextLabelContainer, mainView, errorLabelContainer, secondaryViewsStackView].compactMap { $0 }

        contentStack = CustomSpacingStackView(customSpacedArrangedSubviews: subviews)
        contentStack.axis = .vertical
        contentStack.distribution = .fill
        contentStack.alignment = .fill

        view.addSubview(contentStack)
        view.addSubview(footerViewStackView)
    }

    func setSecondaryViewHidden(_ isHidden: Bool) {
        secondaryViewsStackView.isHidden = isHidden
    }

    /**
     * Updates the constrains for display in regular or compact layout.
     * - parameter isRegular: Whether the current size class is regular.
     */

    func updateConstraints(forRegularLayout isRegular: Bool) {
        if isRegular {
            mainViewWidthCompact.isActive = false
            mainViewWidthRegular.isActive = true
        } else {
            mainViewWidthRegular.isActive = false
            mainViewWidthCompact.isActive = true
        }
    }

    func createConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Arrangement
        headlineLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        mainView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        mainView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Spacing
        if stepDescription.subtext != nil {
            subtextLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
            subtextLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -64).isActive = true
            contentStack.wr_addCustomSpacing(16, after: headlineLabelContainer)
            contentStack.wr_addCustomSpacing(44, after: subtextLabelContainer)
        } else {
            contentStack.wr_addCustomSpacing(contentCenterConstraintActivation ? 44 : 0, after: headlineLabelContainer)
        }

        contentStack.wr_addCustomSpacing(16, after: mainView)
        contentStack.wr_addCustomSpacing(16, after: errorLabelContainer)

        // Fixed Constraints
        contentCenter = contentCenterYAnchor.constraint(equalTo: view.centerYAnchor)
        contentCenter.isActive = contentCenterConstraintActivation
        contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = contentCenterConstraintActivation

        let labelConstraint = headlineLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -64)
        labelConstraint.priority = .init(999)

        NSLayoutConstraint.activate([
            // contentStack
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -10),

            // labels
            labelConstraint,

            // height
            mainView.heightAnchor.constraint(greaterThanOrEqualToConstant: AuthenticationStepController.mainViewHeight),
            secondaryViewsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 13),
            errorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 19)

        ])

        if stepDescription.footerView != nil {
            NSLayoutConstraint.activate([
                footerViewStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
                footerViewStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -31),
                footerViewStackView.safeBottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -20)
            ])
        }

        // Adaptive Constraints
        mainViewWidthRegular = mainView.widthAnchor.constraint(equalToConstant: 375)
        mainViewWidthCompact = mainView.widthAnchor.constraint(equalTo: view.widthAnchor)

        updateConstraints(forRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

    // MARK: - Customization

    func setRightItem(_ title: String, withAction action: AuthenticationCoordinatorAction, accessibilityID: String) {
        let button = UIBarButtonItem(title: title.localizedUppercase, style: .plain, target: self, action: #selector(rightItemTapped))
        button.accessibilityIdentifier = accessibilityID
        rightItemAction = action
        navigationItem.rightBarButtonItem = button
    }

    @objc private func rightItemTapped() {
        guard let rightItemAction = self.rightItemAction else {
            return
        }

        authenticationCoordinator?.executeAction(rightItemAction)
    }

    // MARK: - Back Button

    private func updateBackButton() {
        guard navigationController?.viewControllers.count ?? 0 > 1 else {
            return
        }

        let button = AuthenticationNavigationBar.makeBackButton()
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Keyboard

    private func configureObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardPresentation), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardPresentation), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func handleKeyboardPresentation(notification: Notification) {
        updateOffsetForKeyboard(in: notification)
    }

    private func updateOffsetForKeyboard(in notification: Notification) {
        // Do not change the keyboard frame when there is a modal alert with a text field
        guard presentedViewController == nil else { return }

        let keyboardFrame = UIView.keyboardFrame(in: view, forKeyboardNotification: notification)
        updateKeyboard(with: keyboardFrame)
    }

    func updateKeyboard(with keyboardFrame: CGRect) {
        let minimumKeyboardSpacing: CGFloat = 24
        let currentOffset = abs(contentCenter.constant)

        // Reset the frame when the keyboard is dismissed
        if keyboardFrame.height == 0 {
            return contentCenter.constant = 0
        }

        // Calculate the height of the content under the keyboard
        let contentRect = CGRect(x: contentStack.frame.origin.x,
                                 y: contentStack.frame.origin.y + currentOffset,
                                 width: contentStack.frame.width,
                                 height: contentStack.frame.height + minimumKeyboardSpacing)

        let offset = keyboardFrame.intersection(contentRect).height

        // Adjust if we need more space
        if offset > currentOffset {
            contentCenter.constant = -offset
        }
    }

    func clearInputFields() {
        (mainView as? TextContainer)?.text = nil
        showKeyboard()
    }

    func showKeyboard() {
        mainView.becomeFirstResponderIfPossible()
    }

    func dismissKeyboard() {
        mainView.resignFirstResponder()
    }

    override func accessibilityPerformMagicTap() -> Bool {
        return (mainView as? MagicTappable)?.performMagicTap() == true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

}

// MARK: - Event Handling

extension AuthenticationStepController {

    // MARK: - AuthenticationCoordinatedViewController

    func displayError(_ error: Error) {
        // no-op
    }

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        switch feedbackAction {
        case .clearInputFields:
            clearInputFields()
        case .showGuidanceDot:
            break
        }
    }

    func valueSubmitted(_ value: Any) {
        dismissKeyboard()
        authenticationCoordinator?.handleUserInput(value)
    }

    var initialValidation: ValueValidation? {
        return (stepDescription as? DefaultValidatingStepDescription)?.initialValidation
    }

    func valueValidated(_ validation: ValueValidation?) {
        updateValidation(validation ?? initialValidation)
    }

    func updateValidation(_ suggestedValidation: ValueValidation?) {
        switch suggestedValidation {
        case .info(let infoText)?:
            errorLabel.accessibilityIdentifier = "validation-rules"
            errorLabel.text = infoText
            errorLabel.textColor = UIColor.Team.placeholderColor
            errorLabelContainer.isHidden = false
            showSecondaryView(for: nil)

        case .error(let error, let showVisualFeedback)?:
            if !showVisualFeedback {
                // If we do not want to show an error (eg if all the text was deleted,
                // either use the initial info or clear the error
                return updateValidation(initialValidation)
            }

            errorLabel.accessibilityIdentifier = "validation-failure"
            errorLabel.text = error.errorDescription
            errorLabel.textColor = SemanticColors.Label.textErrorDefault
            errorLabelContainer.isHidden = false
            showSecondaryView(for: error)

        case nil:
            clearError()
        }
    }
}

// MARK: - Error handling

extension AuthenticationStepController {
    func clearError() {
        errorLabel.text = nil
        errorLabelContainer.isHidden = true
        showSecondaryView(for: nil)
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
