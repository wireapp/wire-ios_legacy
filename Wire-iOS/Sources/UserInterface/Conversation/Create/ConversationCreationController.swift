////
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
import Cartography

final public class ConversationCreationValues {
    var name: String
    var participants: Set<ZMUser>
    init (name: String, participants: Set<ZMUser> = []) {
        self.name = name
        self.participants = participants
    }
}

final class ConversationCreationController: UIViewController {

    static let errorFont = FontSpec(.small, .semibold).font!

    static let mainViewHeight: CGFloat = 56

    fileprivate var errorLabel: UILabel!

    fileprivate var errorViewContainer: UIView!
    private var mainViewContainer: UIView!

    private let backButtonDescription = BackButtonDescription()
    private var backButton: UIView!
    fileprivate var nextButton: UIButton!

    private var textField: SimpleTextField!
    private var textFieldValidator = SimpleTextFieldValidator()
    fileprivate var secondaryErrorView: UIView?
    
    fileprivate var values: ConversationCreationValues?

    typealias CreationCloseClosure = (UIViewController) -> Void
    fileprivate var onClose: CreationCloseClosure?

    init(onClose: CreationCloseClosure? = nil) {
        self.onClose = onClose
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
        title = "create group".uppercased()

        createViews()
        createConstraints()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func createViews() {
        mainViewContainer = UIView()
        mainViewContainer.translatesAutoresizingMaskIntoConstraints = false

        backButtonDescription.buttonTapped = { [unowned self] in
            self.onClose?(self)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButtonDescription.create())

        nextButton = ButtonWithLargerHitArea()
        nextButton.setTitle("general.next".localized.uppercased(), for: .normal)
        let textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .light)
        nextButton.setTitleColor(textColor, for: .normal)
        nextButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconHighlighted, variant: .light), for: .highlighted)
        nextButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconShadow, variant: .light), for: .disabled)

        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        nextButton.titleLabel?.font = FontSpec(.medium, .medium).font!

        navigationController?.navigationBar.tintColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground),
                                                  NSFontAttributeName: FontSpec(.normal, .medium).font!.allCaps()]

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextButton)

        textField = SimpleTextField()
        textField.placeholder = "conversation.create.group_name.placeholder".localized.uppercased()
        textField.textFieldDelegate = self
        mainViewContainer.addSubview(textField)

        errorViewContainer = UIView()
        errorViewContainer.translatesAutoresizingMaskIntoConstraints = false

        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.font = TeamCreationStepController.errorFont
        errorLabel.textColor = UIColor.Team.errorMessageColor
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorViewContainer.addSubview(errorLabel)

        [mainViewContainer,
         errorViewContainer].flatMap {$0}.forEach {
            self.view.addSubview($0)
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

            constrain(view, backButton) { view, backButton in
                backButton.leading == view.leading + 16
                backButton.top == view.topMargin + backButtonTopMargin
                backButton.height == backButtonSize
                backButton.height == backButton.width
            }
        }

        constrain(view, errorViewContainer, mainViewContainer) { view, errorViewContainer, mainViewContainer in
            errorViewContainer.bottom == view.bottom - 25
            errorViewContainer.leading == view.leading
            errorViewContainer.trailing == view.trailing
            errorViewContainer.height == 30
            mainViewContainer.bottom == errorViewContainer.top
            mainViewContainer.centerX == view.centerX
            mainViewContainer.width == view.width
        }

        constrain(mainViewContainer, textField) { mainViewContainer, textField in
            textField.height == TeamCreationStepController.mainViewHeight
            textField.top == mainViewContainer.top
            textField.leading == mainViewContainer.leading
            textField.trailing == mainViewContainer.trailing
            textField.bottom == mainViewContainer.bottom
        }

        constrain(errorViewContainer, errorLabel) { errorViewContainer, errorLabel in
            errorLabel.centerY == errorViewContainer.centerY
            errorLabel.leading == errorViewContainer.leadingMargin
            errorLabel.trailing == errorViewContainer.trailingMargin
            errorLabel.topMargin == errorViewContainer.topMargin
            errorLabel.bottomMargin == errorViewContainer.bottomMargin
            errorLabel.height >= 19
        }
    }

    func proceedWith(value: SimpleTextField.Value) {
        switch value {
        case let .error(error):
            displayError(error)
        case let .valid(name):
            textField.resignFirstResponder()
            let newValues = ConversationCreationValues(name: name, participants: values?.participants ?? [])
            values = newValues
            let participantsController = AddParticipantsViewController(context: .create(newValues))
            participantsController.conversationCreationDelegate = self
            navigationController?.pushViewController(participantsController, animated: true)
        }
    }

    @objc fileprivate func nextButtonTapped(_ sender: UIButton) {
        guard let value = textField.value else { return }
        proceedWith(value: value)
    }
}

// MARK: - AddParticipantsConversationCreationDelegate

extension ConversationCreationController: AddParticipantsConversationCreationDelegate {
    
    func addParticipantsViewController(_ addParticipantsViewController: AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction) {
        switch action {
        case .updatedUsers(let users):
            values = values.map { .init(name: $0.name, participants: users) }
        case .create: break
            // TODO
        }
    }
}

// MARK: - SimpleTextFieldDelegate

extension ConversationCreationController: SimpleTextFieldDelegate {
    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value?) {
        clearError()
        nextButton.isEnabled = (value != nil)
    }

    func textFieldReturnPressed(_ textField: SimpleTextField) {
        nextButtonTapped(nextButton)
    }
}


// MARK: - Error handling
extension ConversationCreationController {
    func clearError() {
        errorLabel.text = nil
        self.errorViewContainer.setNeedsLayout()
    }

    func displayError(_ error: Error) {
        errorLabel.text = error.localizedDescription.uppercased()
        self.errorViewContainer.setNeedsLayout()
    }
}
