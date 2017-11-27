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

    static let headlineFont = FontSpec(.large, .light, .largeTitle).font!
    static let subtextFont = FontSpec(.normal, .regular).font!
    static let errorFont = FontSpec(.small, .semibold).font!
    static let textButtonFont = FontSpec(.small, .semibold).font!

    let headline: String
    let subtext: String?
    let backButtonDescriptor: ViewDescriptor?
    let mainViewDescriptor: ViewDescriptor
    let secondaryViewDescriptors: [ViewDescriptor]

    private var stackView: UIStackView!
    private var headlineLabel: UILabel!
    private var subtextLabel: UILabel!
    fileprivate var errorLabel: UILabel!

    private var secondaryViewsStackView: UIStackView!
    private var errorViewContainer: UIView!
    private var mainViewContainer: UIView!

    private var backButton: UIView?

    private var mainView: UIView!
    private var secondaryViews: [UIView] = []

    private var keyboardOffset: NSLayoutConstraint!

    init(headline: String, subtext: String? = nil, mainView: ViewDescriptor, backButton: ViewDescriptor? = nil, secondaryViews: [ViewDescriptor] = []) {
        self.headline = headline
        self.subtext = subtext
        self.mainViewDescriptor = mainView
        self.backButtonDescriptor = backButton
        self.secondaryViewDescriptors = secondaryViews
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Team.background

        createViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        mainView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        NotificationCenter.default.removeObserver(self)
    }

    dynamic func keyboardWillShow(_ notification: Notification) {
        animateViewsToAccomodateKeyboard(with: notification)
    }

    dynamic func keyboardWillChangeFrame(_ notification: Notification) {
        animateViewsToAccomodateKeyboard(with: notification)
    }

    func animateViewsToAccomodateKeyboard(with notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            self.keyboardOffset.constant = -(keyboardHeight + 10)
            self.view.setNeedsLayout()
        }
    }

    private func createViews() {
        backButton = backButtonDescriptor?.create()

        headlineLabel = UILabel()
        headlineLabel.textAlignment = .center
        headlineLabel.font = TeamCreationStepController.headlineFont
        headlineLabel.textColor = UIColor.Team.textColor
        headlineLabel.text = headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        subtextLabel = UILabel()
        subtextLabel.textAlignment = .center
        subtextLabel.text = subtext
        subtextLabel.font = TeamCreationStepController.subtextFont
        subtextLabel.textColor = UIColor.Team.subtitleColor
        subtextLabel.numberOfLines = 0
        subtextLabel.lineBreakMode = .byWordWrapping
        subtextLabel.translatesAutoresizingMaskIntoConstraints = false

        mainViewContainer = UIView()
        mainViewContainer.translatesAutoresizingMaskIntoConstraints = false

        mainView = mainViewDescriptor.create()
        mainViewContainer.addSubview(mainView)

        errorViewContainer = UIView()
        errorViewContainer.translatesAutoresizingMaskIntoConstraints = false

        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.font = TeamCreationStepController.errorFont.allCaps()
        errorLabel.textColor = UIColor.Team.errorMessageColor
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorViewContainer.addSubview(errorLabel)

        secondaryViews = secondaryViewDescriptors.map { $0.create() }

        secondaryViewsStackView = UIStackView(arrangedSubviews: secondaryViews)
        secondaryViewsStackView.distribution = .equalCentering
        secondaryViewsStackView.spacing = 24
        secondaryViewsStackView.translatesAutoresizingMaskIntoConstraints = false

        [backButton, headlineLabel, subtextLabel, mainViewContainer, errorViewContainer, secondaryViewsStackView].flatMap {$0}.forEach { self.view.addSubview($0) }
    }

    private func createConstraints() {
        if let backButton = backButton {
            constrain(view, backButton) { view, backButton in
                backButton.leading == view.leading + 16
                backButton.top == view.topMargin + 12
            }
        }

        constrain(view, secondaryViewsStackView, errorViewContainer, mainViewContainer) { view, secondaryViewsStackView, errorViewContainer, mainViewContainer in
            let keyboardHeight = KeyboardFrameObserver.shared().keyboardFrame().height
            self.keyboardOffset = secondaryViewsStackView.bottom == view.bottom - (keyboardHeight + 10)
            secondaryViewsStackView.leading >= view.leading
            secondaryViewsStackView.trailing <= view.trailing
            secondaryViewsStackView.height == 42
            secondaryViewsStackView.centerX == view.centerX

            errorViewContainer.bottom == secondaryViewsStackView.top
            errorViewContainer.leading == view.leading
            errorViewContainer.trailing == view.trailing
            errorViewContainer.height == 30

            mainViewContainer.bottom == errorViewContainer.top
            mainViewContainer.leading == view.leading
            mainViewContainer.trailing == view.trailing
            mainViewContainer.height == 2 * 56 // Space for two text fields
        }

        constrain(view, mainViewContainer, subtextLabel, headlineLabel) { view, inputViewsContainer, subtextLabel, headlineLabel in
            headlineLabel.bottom == subtextLabel.top - 24
            headlineLabel.leading == view.leadingMargin
            headlineLabel.trailing == view.trailingMargin

            subtextLabel.bottom == inputViewsContainer.top - 24
            subtextLabel.leading == view.leadingMargin
            subtextLabel.trailing == view.trailingMargin
        }

        constrain(mainViewContainer, mainView) { mainViewContainer, mainView in
            mainView.edges == inset(mainViewContainer.edges, 56, 0, 0, 0)
        }

        constrain(errorViewContainer, errorLabel) { errorViewContainer, errorLabel in
            errorLabel.centerY == errorViewContainer.centerY
            errorLabel.leading == errorViewContainer.leadingMargin
            errorLabel.trailing == errorViewContainer.trailingMargin
        }
    }
}

// MARK: - Error handling
extension TeamCreationStepController {

    func displayError(_ error: Error) {
        let nsError = error as NSError
        errorLabel.text = nsError.localizedDescription
    }

}
