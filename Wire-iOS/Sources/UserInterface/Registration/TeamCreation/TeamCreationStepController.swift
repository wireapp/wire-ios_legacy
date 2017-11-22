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

    let headline: String
    let subtext: String?
    let backButtonDescriptor: ViewDescriptor?
    let mainViewDescriptor: ViewDescriptor
    let secondaryViewDescriptors: [ViewDescriptor]

    private var stackView: UIStackView!
    private var headlineLabel: UILabel!
    private var subtextLabel: UILabel!
    private var errorLabel: UILabel!

    private var secondaryViewsContainer: UIView!
    private var errorViewContainer: UIView!
    private var mainViewContainer: UIView!

    private var backButton: UIView?

    private var mainView: UIView!
    private var secondaryViews: [UIView] = []

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

        view.backgroundColor = #colorLiteral(red: 0.9724436402, green: 0.972609818, blue: 0.9724331498, alpha: 1)

        createViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
        mainView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
    }

    private func createViews() {
        backButton = backButtonDescriptor?.create()

        headlineLabel = UILabel()
        headlineLabel.backgroundColor = .yellow
        headlineLabel.text = headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        subtextLabel = UILabel()
        subtextLabel.backgroundColor = .gray
        subtextLabel.text = subtext
        subtextLabel.translatesAutoresizingMaskIntoConstraints = false

        mainViewContainer = UIView()
        mainViewContainer.backgroundColor = .gray
        mainViewContainer.translatesAutoresizingMaskIntoConstraints = false

        mainView = mainViewDescriptor.create()
        mainViewContainer.addSubview(mainView)

        errorViewContainer = UIView()
        errorViewContainer.backgroundColor = .red
        errorViewContainer.translatesAutoresizingMaskIntoConstraints = false

        errorLabel = UILabel()
        errorLabel.backgroundColor = .gray
        errorLabel.text = "SOME ERROR OCCURED"
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorViewContainer.addSubview(errorLabel)

        secondaryViewsContainer = UIView()
        secondaryViewsContainer.backgroundColor = .lightGray
        secondaryViewsContainer.translatesAutoresizingMaskIntoConstraints = false

        secondaryViews = secondaryViewDescriptors.map { $0.create() }
        secondaryViews.forEach { self.secondaryViewsContainer.addSubview($0) }

        [backButton, headlineLabel, subtextLabel, mainViewContainer, errorViewContainer, secondaryViewsContainer].flatMap {$0}.forEach { self.view.addSubview($0) }
    }

    private func createConstraints() {

        if let backButton = backButton {
            constrain(view, backButton) { view, backButton in
                backButton.leading == view.leading
                backButton.top == view.topMargin
            }
        }

        constrain(view, secondaryViewsContainer, errorViewContainer, mainViewContainer) { view, secondaryViewsContainer, errorViewContainer, mainViewContainer in
            secondaryViewsContainer.bottom == view.bottom - (258 + 10)
            secondaryViewsContainer.leading == view.leading
            secondaryViewsContainer.trailing == view.trailing
            secondaryViewsContainer.height == 42

            errorViewContainer.bottom == secondaryViewsContainer.top
            errorViewContainer.leading == view.leading
            errorViewContainer.trailing == view.trailing
            errorViewContainer.height == 30

            mainViewContainer.bottom == errorViewContainer.top
            mainViewContainer.leading == view.leading
            mainViewContainer.trailing == view.trailing
            mainViewContainer.height == 2 * 56 // Space for two text fields
        }

        constrain(view, mainViewContainer, subtextLabel, headlineLabel) { view, inputViewsContainer, subtextLabel, headlineLabel in
            headlineLabel.bottom == inputViewsContainer.top - 58
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
            errorLabel.top == errorViewContainer.top + 16
            errorLabel.leading == errorViewContainer.leadingMargin
            errorLabel.trailing == errorViewContainer.trailingMargin
        }

    }
}
