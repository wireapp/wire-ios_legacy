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

open class ConversationCreationTitleFactory {
    static func createTitleLabel(for title: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.font = FontSpec(.normal, .medium).font!.allCaps()
        titleLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .light)
        titleLabel.text = title
        titleLabel.sizeToFit()
        return titleLabel
    }
}

final class ConversationCreationController: UIViewController {

    static let errorFont = FontSpec(.small, .semibold).font!

    static let mainViewHeight: CGFloat = 56

    fileprivate var errorLabel: UILabel!

    fileprivate var errorViewContainer: UIView!
    private var mainViewContainer: UIView!

    private let backButtonDescription = BackButtonDescription()
    fileprivate var nextButton: UIButton!

    private var textField: SimpleTextField!
    private var textFieldValidator = SimpleTextFieldValidator()
    fileprivate var secondaryErrorView: UIView?
    
    fileprivate var values: ConversationCreationValues?

    typealias CreationCloseClosure = (ConversationCreationValues?) -> Void
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
        
        setupNavigationBar()
        createViews()
        createConstraints()
        
        // try to overtake the first responder from the other view
        if let _ = UIResponder.wr_currentFirst() {
            self.textField.becomeFirstResponder()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default().variant == .dark ? .lightContent : .default
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    private func createViews() {
        mainViewContainer = UIView()
        mainViewContainer.translatesAutoresizingMaskIntoConstraints = false

        textField = SimpleTextField()
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "textfield.newgroup.name"
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

    private func setupNavigationBar() {
        
        // left button
        backButtonDescription.buttonTapped = { [unowned self] in self.onClose?(nil) }
        backButtonDescription.accessibilityIdentifier = "button.newgroup.back"

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButtonDescription.create())

        // title view
        navigationItem.titleView = ConversationCreationTitleFactory.createTitleLabel(for: self.title ?? "")
        
        // right button
        nextButton = ButtonWithLargerHitArea(type: .custom)
        nextButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        nextButton.accessibilityIdentifier = "button.newgroup.next"
        nextButton.setTitle("general.next".localized.uppercased(), for: .normal)
        nextButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .light), for: .normal)
        nextButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorTextDimmed, variant: .light), for: .highlighted)
        nextButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconShadow, variant: .light), for: .disabled)
        nextButton.titleLabel?.font = FontSpec(.medium, .medium).font!
        nextButton.sizeToFit()
        
        nextButton.addCallback(for: .touchUpInside) { [weak self] _ in
            self?.tryToProceed()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextButton)
    }
    
    private func createConstraints() {
        
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
    
    fileprivate func tryToProceed() {
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
        case .create:
            onClose?(values)
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
        tryToProceed()
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
