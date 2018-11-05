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
    var allowGuests: Bool
    var name: String
    var participants: Set<ZMUser>
    init (name: String, participants: Set<ZMUser> = [], allowGuests: Bool) {
        self.name = name
        let selfUser = ZMUser.selfUser()!
        self.participants = allowGuests ? participants : Set(Array(participants).filter { $0.team == selfUser.team })
        self.allowGuests = allowGuests
    }
}

@objc protocol ConversationCreationControllerDelegate: class {

    func conversationCreationController(
        _ controller: ConversationCreationController,
        didSelectName name: String,
        participants: Set<ZMUser>,
        allowGuests: Bool
    )
    
}

@objcMembers final class ConversationCreationController: UIViewController {

    static let errorFont = FontSpec(.small, .semibold).font!
    static let mainViewHeight: CGFloat = 56

    fileprivate let errorLabel = UILabel()
    fileprivate let errorViewContainer = UIView()
    fileprivate let colorSchemeVariant = ColorScheme.default.variant
    private let mainViewContainer = UIView()
    private let bottomViewContainer = UIView()
    private let toggleSubtitleLabel = UILabel()
    private let textFieldSubtitleLabel = UILabel()
    private let toggleView = ToggleView(
        title: "conversation.create.toggle.title".localized,
        isOn: true,
        accessibilityIdentifier: "toggle.newgroup.allowguests"
    )

    fileprivate var navigationBarBackgroundView = UIView()

    private var textField = SimpleTextField()
    
    fileprivate var values: ConversationCreationValues?
    fileprivate let source: LinearGroupCreationFlowEvent.Source
    
    weak var delegate: ConversationCreationControllerDelegate?
    private var preSelectedParticipants: Set<ZMUser>?
    
    @objc public convenience init(preSelectedParticipants: Set<ZMUser>) {
        self.init(source: .conversationDetails)
        self.preSelectedParticipants = preSelectedParticipants
    }
    
    public init(source: LinearGroupCreationFlowEvent.Source = .startUI) {
        self.source = source
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
        Analytics.shared().tagLinearGroupOpened(with: self.source)

        view.backgroundColor = UIColor.from(scheme: .contentBackground, variant: colorSchemeVariant)
        title = "conversation.create.group_name.title".localized.uppercased()
        
        setupNavigationBar()
        setupViews()
        createConstraints()
        
        // try to overtake the first responder from the other view
        if let _ = UIResponder.wr_currentFirst() {
            self.textField.becomeFirstResponder()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return colorSchemeVariant == .light ? .default : .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    private func setupViews() {
        mainViewContainer.translatesAutoresizingMaskIntoConstraints = false
        navigationBarBackgroundView.backgroundColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
        mainViewContainer.addSubview(navigationBarBackgroundView)
        
        textField = SimpleTextField()
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "textfield.newgroup.name"
        textField.placeholder = "conversation.create.group_name.placeholder".localized.uppercased()
        textField.textFieldDelegate = self
        mainViewContainer.addSubview(textField)
        if ZMUser.selfUser().hasTeam {
            mainViewContainer.addSubview(textFieldSubtitleLabel)
            textFieldSubtitleLabel.numberOfLines = 0
        }
        errorViewContainer.translatesAutoresizingMaskIntoConstraints = false

        errorLabel.textAlignment = .center
        errorLabel.font = TeamCreationStepController.errorFont
        errorLabel.textColor = UIColor.Team.errorMessageColor
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorViewContainer.addSubview(errorLabel)
        toggleSubtitleLabel.numberOfLines = 0
        
        [toggleSubtitleLabel, textFieldSubtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .preferredFont(forTextStyle: .footnote)
            $0.textColor = UIColor.from(scheme: .textDimmed)
        }
        
        toggleSubtitleLabel.text = "conversation.create.toggle.subtitle".localized
        textFieldSubtitleLabel.text = "participants.section.name.footer".localized(args: ZMConversation.maxParticipants, ZMConversation.maxVideoCallParticipantsExcludingSelf)
        
        [toggleView, toggleSubtitleLabel].forEach(bottomViewContainer.addSubview)
        [mainViewContainer, errorViewContainer, bottomViewContainer].forEach(view.addSubview)
        
        toggleView.handler = { [unowned self] allowGuests in
            self.values = ConversationCreationValues(
                name: self.values?.name ?? "",
                participants: self.values?.participants ?? [],
                allowGuests: allowGuests
            )
        }
        
        bottomViewContainer.isHidden = nil == ZMUser.selfUser().team
    }

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        self.navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: colorSchemeVariant)
        
        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = navigationController?.closeItem()
        }
        
        let nextButtonItem = UIBarButtonItem(title: "general.next".localized.uppercased(), style: .plain, target: self, action: #selector(tryToProceed))
        nextButtonItem.accessibilityIdentifier = "button.newgroup.next"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false
    
        navigationItem.rightBarButtonItem = nextButtonItem
    }
    
    private func createConstraints() {
        constrain(toggleView, toggleSubtitleLabel, bottomViewContainer) { toggleView, toggleSubtitleLabel, container in
            toggleView.leading == container.leading
            toggleView.trailing == container.trailing
            toggleSubtitleLabel.leading == container.leading + 16
            toggleSubtitleLabel.trailing == container.trailing - 16
            toggleView.top == container.top
            toggleSubtitleLabel.top == toggleView.bottom + 16
            toggleSubtitleLabel.bottom == container.bottom
        }
        
        constrain(view, errorViewContainer, bottomViewContainer) { view, errorViewContainer, bottomViewContainer in
            bottomViewContainer.top == errorViewContainer.bottom + 8
            bottomViewContainer.leading == view.leading
            bottomViewContainer.trailing == view.trailing
        }
        
        constrain(view, navigationBarBackgroundView, self.car_topLayoutGuide, mainViewContainer) { view, navigationBarBackgroundView, topLayoutGuide, mainViewContainer in
            navigationBarBackgroundView.leading == view.leading
            navigationBarBackgroundView.trailing == view.trailing
            navigationBarBackgroundView.top == view.top
            navigationBarBackgroundView.bottom == topLayoutGuide.bottom
            
            mainViewContainer.top == navigationBarBackgroundView.bottom + 32
        }
        
        constrain(view, errorViewContainer, mainViewContainer) { view, errorViewContainer, mainViewContainer in
            errorViewContainer.leading == view.leading
            errorViewContainer.trailing == view.trailing
            errorViewContainer.height == 48

            mainViewContainer.bottom == errorViewContainer.top
            mainViewContainer.centerX == view.centerX
            mainViewContainer.width == view.width
        }

        constrain(mainViewContainer, textField, textFieldSubtitleLabel) { mainViewContainer, textField, textFieldSubtitleLabel in
            textField.height == TeamCreationStepController.mainViewHeight
            textField.top == mainViewContainer.top
            textField.leading == mainViewContainer.leading
            textField.trailing == mainViewContainer.trailing
            
            if ZMUser.selfUser().hasTeam {
                textFieldSubtitleLabel.leading == mainViewContainer.leading + 16
                textFieldSubtitleLabel.trailing == mainViewContainer.trailing - 16
                textFieldSubtitleLabel.bottom == mainViewContainer.bottom - 24
                textField.bottom == textFieldSubtitleLabel.top - 16
            } else {
                textField.bottom == mainViewContainer.bottom
            }
        }

        constrain(errorViewContainer, errorLabel) { errorViewContainer, errorLabel in
            errorLabel.leading == errorViewContainer.leadingMargin
            errorLabel.trailing == errorViewContainer.trailingMargin
            errorLabel.top == errorViewContainer.top + 16
            errorLabel.bottom <= errorViewContainer.bottom - 16
        }
    }

    func proceedWith(value: SimpleTextField.Value) {
        switch value {
        case let .error(error):
            displayError(error)
        case let .valid(name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            textField.resignFirstResponder()
            let newValues = ConversationCreationValues(name: trimmed, participants: preSelectedParticipants ?? values?.participants ?? [], allowGuests: values?.allowGuests ?? true)
            values = newValues
            
            Analytics.shared().tagLinearGroupSelectParticipantsOpened(with: self.source)
            
            let participantsController = AddParticipantsViewController(context: .create(newValues), variant: colorSchemeVariant)
            participantsController.conversationCreationDelegate = self
            navigationController?.pushViewController(participantsController, animated: true)
        }
    }
    
    @objc fileprivate func tryToProceed() {
        guard let value = textField.value else { return }
        proceedWith(value: value)
    }
}

// MARK: - AddParticipantsConversationCreationDelegate

extension ConversationCreationController: AddParticipantsConversationCreationDelegate {
    
    func addParticipantsViewController(_ addParticipantsViewController: AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction) {
        switch action {
        case .updatedUsers(let users):
            values = values.map { .init(name: $0.name, participants: users, allowGuests: $0.allowGuests) }
        case .create:
            values.apply {
                var allParticipants = $0.participants
                allParticipants.insert(ZMUser.selfUser())
                Analytics.shared().tagLinearGroupCreated(with: self.source, isEmpty: $0.participants.isEmpty, allowGuests: $0.allowGuests)
                Analytics.shared().tagAddParticipants(source: self.source, allParticipants, allowGuests: $0.allowGuests, in: nil)

                delegate?.conversationCreationController(
                    self,
                    didSelectName: $0.name,
                    participants: $0.participants,
                    allowGuests: $0.allowGuests
                )
            }
        }
    }
}

// MARK: - SimpleTextFieldDelegate

extension ConversationCreationController: SimpleTextFieldDelegate {

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {
        clearError()
        switch value {
        case .error(_): navigationItem.rightBarButtonItem?.isEnabled = false
        case .valid(let text): navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
        }
        
    }

    func textFieldReturnPressed(_ textField: SimpleTextField) {
        tryToProceed()
    }
    
    func textFieldDidBeginEditing(_ textField: SimpleTextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: SimpleTextField) {
        
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
