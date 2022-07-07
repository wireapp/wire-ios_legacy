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
import WireDataModel

protocol ConversationCreationValuesConfigurable: AnyObject {
    func configure(with values: ConversationCreationValues)
}

final class ConversationCreationValues {

    private var unfilteredParticipants: UserSet
    private let selfUser: UserType

    var name: String
    var allowGuests: Bool
    var allowServices: Bool
    var enableReceipts: Bool
    var encryptionProtocol: EncryptionProtocol

    var participants: UserSet {
        get {
            var result = unfilteredParticipants

            if !allowGuests {
                let noGuests = result.filter { $0.isOnSameTeam(otherUser: selfUser) }
                result = UserSet(noGuests)
            }

            if !allowServices {
                let noServices = result.filter { !$0.isServiceUser }
                result = UserSet(noServices)
            }

            return result
        }
        set {
            unfilteredParticipants = newValue
        }
    }

    init(
        name: String = "",
        participants: UserSet = UserSet(),
        allowGuests: Bool = true,
        allowServices: Bool = true,
        enableReceipts: Bool = true,
        encryptionProtocol: EncryptionProtocol = .proteus,
        selfUser: UserType
    ) {
        self.name = name
        self.unfilteredParticipants = participants
        self.allowGuests = allowGuests
        self.allowServices = allowServices
        self.enableReceipts = enableReceipts
        self.encryptionProtocol = encryptionProtocol
        self.selfUser = selfUser
    }
}

protocol ConversationCreationControllerDelegate: AnyObject {

    func conversationCreationController(
        _ controller: ConversationCreationController,
        didSelectName name: String,
        participants: UserSet,
        allowGuests: Bool,
        allowServices: Bool,
        enableReceipts: Bool,
        encryptionProtocol: EncryptionProtocol
    )

}

final class ConversationCreationController: UIViewController {

    // MARK: - Properties

    private let selfUser: UserType
    private let colorSchemeVariant = ColorScheme.default.variant
    private let collectionViewController = SectionCollectionViewController()

    private var preSelectedParticipants: UserSet?
    private var values: ConversationCreationValues

    weak var delegate: ConversationCreationControllerDelegate?

    // MARK: - Sections

    private lazy var nameSection = ConversationCreateNameSectionController(selfUser: selfUser, delegate: self)
    private lazy var errorSection = ConversationCreateErrorSectionController()

    private lazy var optionsToggle: ConversationCreateOptionsSectionController = {
        let section = ConversationCreateOptionsSectionController(values: values)
        section.tapHandler = optionsTapped
        return section
    }()

    private lazy var optionsSections = [
        guestsSection,
        servicesSection,
        receiptsSection,
        selfUser.canCreateMLSGroups || DeveloperFlag.showCreateMLSGroupToggle.isOn ? encryptionProtocolSection : nil
    ].compactMap(\.self)

    private lazy var guestsSection: ConversationCreateGuestsSectionController = {
        let section = ConversationCreateGuestsSectionController(values: values)
        section.isHidden = true

        section.toggleAction = { [unowned self] allowGuests in
            self.values.allowGuests = allowGuests
            self.updateOptions()
        }

        return section
    }()

    private lazy var servicesSection: ConversationCreateServicesSectionController = {
        let section = ConversationCreateServicesSectionController(values: values)
        section.isHidden = true

        section.toggleAction = { [unowned self] allowServices in
            self.values.allowServices = allowServices
            self.updateOptions()
        }
        return section
    }()

    private lazy var receiptsSection: ConversationCreateReceiptsSectionController = {
        let section = ConversationCreateReceiptsSectionController(values: values)
        section.isHidden = true

        section.toggleAction = { [unowned self] enableReceipts in
            self.values.enableReceipts = enableReceipts
            self.updateOptions()
        }

        return section
    }()

    private lazy var encryptionProtocolSection: ConversationEncryptionProtocolSectionController = {
        let section = ConversationEncryptionProtocolSectionController(values: values)
        section.isHidden = true

        section.tapAction = {
            self.presentEncryptionProtocolPicker { [weak self] encryptionProtocol in
                self?.values.encryptionProtocol = encryptionProtocol
                self?.updateOptions()
            }
        }

        return section
    }()

    // MARK: - Life cycle

    convenience init() {
        self.init(preSelectedParticipants: nil, selfUser: ZMUser.selfUser())
    }

    init(preSelectedParticipants: UserSet?, selfUser: UserType) {
        self.selfUser = selfUser
        self.values = ConversationCreationValues(selfUser: selfUser)
        self.preSelectedParticipants = preSelectedParticipants
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.from(scheme: .contentBackground, variant: colorSchemeVariant)
        title = L10n.Localizable.Conversation.Create.GroupName.title.uppercased()

        setupNavigationBar()
        setupViews()

        // try to overtake the first responder from the other view
        if UIResponder.currentFirst != nil {
            nameSection.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameSection.becomeFirstResponder()
    }

    // MARK: - Methods

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    private func setupViews() {
        // TODO: if keyboard is open, it should scroll.
        let collectionView = UICollectionView(forGroupedSections: ())

        collectionView.contentInsetAdjustmentBehavior = .never

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitInSuperview(safely: true)

        collectionViewController.collectionView = collectionView
        collectionViewController.sections = [nameSection, errorSection]

        if selfUser.isTeamMember {
            collectionViewController.sections.append(contentsOf: [optionsToggle] + optionsSections)
        }
    }

    private func setupNavigationBar() {
        let navBarBackgroundView = UIView()
        navBarBackgroundView.backgroundColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
        view.addSubview(navBarBackgroundView)

        navBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            navBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeTopAnchor)
        ])

        navigationController?.navigationBar.tintColor = UIColor.from(
            scheme: .textForeground,
            variant: colorSchemeVariant
        )

        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: colorSchemeVariant)

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = navigationController?.closeItem()
        }

        let nextButtonItem = UIBarButtonItem(
            title: L10n.Localizable.General.next.uppercased(),
            style: .plain,
            target: self,
            action: #selector(tryToProceed)
        )

        nextButtonItem.accessibilityIdentifier = "button.newgroup.next"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false

        navigationItem.rightBarButtonItem = nextButtonItem
    }

    func proceedWith(value: SimpleTextField.Value) {
        switch value {
        case let .error(error):
            errorSection.displayError(error)

        case let .valid(name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            nameSection.resignFirstResponder()
            values.name = trimmed

            if let parts = preSelectedParticipants {
                values.participants = parts
            }

            let participantsController = AddParticipantsViewController(context: .create(values), variant: colorSchemeVariant)
            participantsController.conversationCreationDelegate = self
            navigationController?.pushViewController(participantsController, animated: true)
        }
    }

    @objc
    private func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }

    private func updateOptions() {
        self.optionsToggle.configure(with: values)
        self.guestsSection.configure(with: values)
        self.servicesSection.configure(with: values)
        self.encryptionProtocolSection.configure(with: values)
    }
}

// MARK: - AddParticipantsConversationCreationDelegate

extension ConversationCreationController: AddParticipantsConversationCreationDelegate {

    func addParticipantsViewController(_ addParticipantsViewController: AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction) {
        switch action {
        case .updatedUsers(let users):
            values.participants = users

        case .create:
            var allParticipants = values.participants
            allParticipants.insert(selfUser)

            delegate?.conversationCreationController(
                self,
                didSelectName: values.name,
                participants: values.participants,
                allowGuests: values.allowGuests,
                allowServices: values.allowServices,
                enableReceipts: values.enableReceipts,
                encryptionProtocol: values.encryptionProtocol
            )
        }
    }
}

// MARK: - SimpleTextFieldDelegate

extension ConversationCreationController: SimpleTextFieldDelegate {

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {
        errorSection.clearError()
        switch value {
        case .error: navigationItem.rightBarButtonItem?.isEnabled = false
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

// MARK: - Handlers

extension ConversationCreationController {

    private func optionsTapped(expanded: Bool) {
        guard let collectionView = collectionViewController.collectionView else {
            return
        }

        let changes: () -> Void
        let indexSet = IndexSet(integersIn: 3..<(3+optionsSections.count))

        if expanded {
            nameSection.resignFirstResponder()
            expandOptions()
            changes = { collectionView.insertSections(indexSet) }
        } else {
            collapseOptions()
            changes = { collectionView.deleteSections(indexSet) }
        }

        collectionView.performBatchUpdates(changes)
    }

    func expandOptions() {
        optionsSections.forEach {
            $0.isHidden = false
        }
    }

    func collapseOptions() {
        optionsSections.forEach {
            $0.isHidden = true
        }
    }

}

extension ConversationCreationController {

    func presentEncryptionProtocolPicker(_ completion: @escaping (EncryptionProtocol) -> Void) {
        let alertViewController = encryptionProtocolPicker { type in
            completion(type)
        }

        alertViewController.configPopover(pointToView: view)
        present(alertViewController, animated: true)
    }

    func encryptionProtocolPicker(_ completion: @escaping (EncryptionProtocol) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: L10n.Localizable.Conversation.Create.Mls.pickerTitle, message: nil, preferredStyle: .actionSheet)

        for encryptionProtocol in EncryptionProtocol.allCases {
            alert.addAction(UIAlertAction(title: encryptionProtocol.rawValue, style: .default, handler: { _ in
                completion(encryptionProtocol)
            }))
        }

        alert.popoverPresentationController?.permittedArrowDirections = [ .up, .down ]
        alert.addAction(UIAlertAction(title: L10n.Localizable.Conversation.Create.Mls.cancel, style: .cancel, handler: nil))

        return alert
    }
}

enum EncryptionProtocol: String, CaseIterable {
    case proteus = "Proteus (default)"
    case mls = "MLS"
}
