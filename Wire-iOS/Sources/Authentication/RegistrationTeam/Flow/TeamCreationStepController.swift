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

final class TeamCreationStepController: AuthenticationStepViewController {

    weak var authenticationCoordinator: AuthenticationCoordinator? {
        didSet {
            stepDescription.secondaryView?.actioner = authenticationCoordinator
        }
    }

    /// headline font size is fixed and not affected by dynamic type setting,
    static let headlineFont         = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.light)
    /// For 320 pt width screen
    static let headlineSmallFont    = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight.light)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        mainView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        NotificationCenter.default.removeObserver(self)
        mainView.resignFirstResponder()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateMainViewWidthConstraint()
        updateHeadlineLabelFont()
    }

    // MARK: - View creation

    fileprivate func updateHeadlineLabelFont() {
        headlineLabel.font = self.view.frame.size.width > 320 ? TeamCreationStepController.headlineFont : TeamCreationStepController.headlineSmallFont
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
         headlineLabel,
         subtextLabel,
         mainViewContainer,
         errorViewContainer,
         secondaryViewsStackView].compactMap {$0}.forEach {
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
        constrain(view, topSpacer, bottomSpacer) { view, topSpacer, bottomSpacer in
            spacerEqualHeight = bottomSpacer.height == topSpacer.height

            topSpacerHeight = topSpacer.height >= 24
            bottomSpacerHeight = bottomSpacer.height == 24

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
            secondaryViewsStackView.height == 42 ~ 500.0
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

            headlineLabel.bottom == subtextLabel.top - 24 ~ 750.0
            headlineLabel.leading == view.leadingMargin
            headlineLabel.trailing == view.trailingMargin

            subtextLabel.top >= headlineLabel.bottom + 5
            subtextLabel.leading == view.leadingMargin
            subtextLabel.trailing == view.trailingMargin
            subtextLabel.height >= 19

            inputViewsContainer.top >= subtextLabel.bottom + 5
            inputViewsContainer.top == subtextLabel.bottom + 80 ~ 800.0
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

        headlineLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        subtextLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        updateMainViewWidthConstraint()
    }

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        switch feedbackAction {
        case .clearInputFields:
            (mainView as? TextContainer)?.text = nil
        case .showGuidanceDot:
            break
        }
    }

    func valueSubmitted(_ value: String) {
        authenticationCoordinator?.advanceTeamCreation(value: value)
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
