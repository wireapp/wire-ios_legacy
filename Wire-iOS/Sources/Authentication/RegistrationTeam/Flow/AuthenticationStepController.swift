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

/**
 * A view controller that can display the interface from an authentication step.
 */

class AuthenticationStepController: AuthenticationStepViewController {

    /// The step to display.
    let stepDescription: TeamCreationStepDescription

    /// The object that coordinates authentication.
    weak var authenticationCoordinator: AuthenticationCoordinator? {
        didSet {
            stepDescription.secondaryView?.actioner = authenticationCoordinator
        }
    }

    // MARK: - Configuration

    static let mainViewHeight: CGFloat = 56

    static let headlineFont         = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.light)
    static let headlineSmallFont    = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight.light)
    static let subtextFont          = FontSpec(.normal, .regular).font!
    static let errorFont            = FontSpec(.small, .semibold).font!
    static let textButtonFont       = FontSpec(.small, .semibold).font!

    // MARK: - Views

    private var contentStack: CustomSpacingStackView!

    private var headlineLabel: UILabel!
    private var subtextLabel: UILabel!
    private var mainView: UIView!
    fileprivate var errorLabel: UILabel!

    fileprivate var secondaryViews: [UIView] = []
    fileprivate var secondaryErrorView: UIView?
    fileprivate var secondaryViewsStackView: UIStackView!

    private var mainViewWidthRegular: NSLayoutConstraint!
    private var mainViewWidthCompact: NSLayoutConstraint!
    private var contentCenter: NSLayoutConstraint!

    // MARK: - Initialization

    /**
     * Creates the view controller to display the specified interface description.
     * - parameter description: The description of the step interface.
     */

    required init(description: TeamCreationStepDescription) {
        self.stepDescription = description
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

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
        configureObservers()
        mainView.becomeFirstResponderIfPossible()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateConstraints(forRegularLayout: traitCollection.horizontalSizeClass == .regular)
        updateHeadlineLabelFont()
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
        headlineLabel = UILabel()
        headlineLabel.textAlignment = .center
        headlineLabel.textColor = UIColor.Team.textColor
        headlineLabel.text = stepDescription.headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        updateHeadlineLabelFont()

        subtextLabel = UILabel()
        subtextLabel.textAlignment = .center
        subtextLabel.text = stepDescription.subtext
        subtextLabel.font = AuthenticationStepController.subtextFont
        subtextLabel.textColor = UIColor.Team.subtitleColor
        subtextLabel.numberOfLines = 0
        subtextLabel.lineBreakMode = .byWordWrapping

        mainView = createMainView()

        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.font = AuthenticationStepController.errorFont
        errorLabel.textColor = UIColor.Team.errorMessageColor
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        if let secondaryView = stepDescription.secondaryView {
            secondaryViews = secondaryView.views.map { $0.create() }
        }

        secondaryViewsStackView = UIStackView(arrangedSubviews: secondaryViews)
        secondaryViewsStackView.distribution = .equalCentering
        secondaryViewsStackView.spacing = 24
        secondaryViewsStackView.translatesAutoresizingMaskIntoConstraints = false

        let subviews = [headlineLabel, subtextLabel, mainView, errorLabel, secondaryViewsStackView].compactMap { $0 }
        contentStack = CustomSpacingStackView(customSpacedArrangedSubviews: subviews)
        contentStack.axis = .vertical
        contentStack.distribution = .fill

        view.addSubview(contentStack)
    }

    private func updateHeadlineLabelFont() {
        headlineLabel.font = self.view.frame.size.width > 320 ? AuthenticationStepController.headlineFont : AuthenticationStepController.headlineSmallFont
    }

    /**
     * Updates the constrains for display in regular or compact latout.
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

    private func createConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Arrangement
        headlineLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        subtextLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        mainView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        mainView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Spacing
        contentStack.wr_addCustomSpacing(16, after: headlineLabel)
        contentStack.wr_addCustomSpacing(44, after: subtextLabel)
        contentStack.wr_addCustomSpacing(8, after: mainView)
        contentStack.wr_addCustomSpacing(16, after: errorLabel)

        // Fixed Constraints
        contentCenter = contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        NSLayoutConstraint.activate([
            // contentStack
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: safeTopAnchor),
            contentCenter,

            // height
            mainView.heightAnchor.constraint(greaterThanOrEqualToConstant: AuthenticationStepController.mainViewHeight),
            secondaryViewsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 13),
            errorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 19)
        ])

        // Adaptive Constraints
        mainViewWidthRegular = mainView.widthAnchor.constraint(equalToConstant: 375)
        mainViewWidthCompact = mainView.widthAnchor.constraint(equalTo: view.widthAnchor)

        updateConstraints(forRegularLayout: traitCollection.horizontalSizeClass == .regular)
    }

    // MARK: - Keyboard

    private func configureObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardPresentation), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleKeyboardPresentation(notification: Notification) {
        updateOffsetForKeyboard(in: notification)
    }

    private func updateOffsetForKeyboard(in notification: Notification) {
        let keyboardFrame = UIView.keyboardFrame(in: view, forKeyboardNotification: notification)
        let minimumKeyboardSpacing: CGFloat = 24
        let currentOffset = abs(contentCenter.constant)

        // Calculate the height of the content under the keyboard
        let contentRect = CGRect(x: contentStack.frame.origin.x,
                                 y: contentStack.frame.origin.y + currentOffset - minimumKeyboardSpacing / 2,
                                 width: contentStack.frame.width,
                                 height: contentStack.frame.height + minimumKeyboardSpacing)

        let offset = keyboardFrame.intersection(contentRect).height

        // Adjust if we need more space
        if offset > currentOffset {
            contentCenter.constant = -offset
        }
    }

}

// MARK: - Event Handling

extension AuthenticationStepController {
    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        switch feedbackAction {
        case .clearInputFields:
            (mainView as? TextContainer)?.text = nil
            mainView.becomeFirstResponderIfPossible()
        case .showGuidanceDot:
            break
        }
    }

    func valueSubmitted(_ value: Any) {
        mainView.resignFirstResponder()
        authenticationCoordinator?.handleUserInput(value)
    }
}

// MARK: - Error handling

extension AuthenticationStepController {
    func clearError() {
        errorLabel.text = nil
        showSecondaryView(for: nil)
    }

    func displayError(_ error: Error) {
        errorLabel.text = error.localizedDescription.uppercased()
        showSecondaryView(for: error)
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
