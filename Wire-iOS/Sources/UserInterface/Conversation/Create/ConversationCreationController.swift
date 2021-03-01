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

protocol ConversationCreationValuesConfigurable: class {
    func configure(with values: ConversationCreationValues)
}

final class ConversationCreationValues {

    private var unfilteredParticipants: UserSet
    private let selfUser: UserType

    var allowGuests: Bool
    var enableReceipts: Bool
    var name: String
    var participants: UserSet {
        get {
            if allowGuests {
                return unfilteredParticipants
            } else {
                let filteredParticipants = unfilteredParticipants.filter {
                    return $0.isOnSameTeam(otherUser: selfUser)
                }

                return UserSet(filteredParticipants)
            }
        }
        set {
            unfilteredParticipants = newValue
        }
    }

    init (name: String = "",
          participants: UserSet = UserSet(),
          allowGuests: Bool = true,
          enableReceipts: Bool = true,
          selfUser: UserType) {
        self.name = name
        self.unfilteredParticipants = participants
        self.allowGuests = allowGuests
        self.enableReceipts = enableReceipts
        self.selfUser = selfUser
    }
}

protocol ConversationCreationControllerDelegate: class {

    func conversationCreationController(_ controller: ConversationCreationController,
                                        didSelectName name: String,
                                        participants: UserSet,
                                        allowGuests: Bool,
                                        enableReceipts: Bool)

}

final class ConversationCreationController: UIViewController {

    private let selfUser: UserType
    static let mainViewHeight: CGFloat = 56
    fileprivate let colorSchemeVariant = ColorScheme.default.variant

    private let collectionViewController = SectionCollectionViewController()

    private lazy var nameSection: ConversationCreateNameSectionController = ConversationCreateNameSectionController(selfUser: selfUser, delegate: self)

    private lazy var errorSection: ConversationCreateErrorSectionController = {
        return ConversationCreateErrorSectionController()
    }()

    private lazy var optionsSection: ConversationCreateOptionsSectionController = {
        let section = ConversationCreateOptionsSectionController(values: self.values)
        section.tapHandler = self.optionsTapped
        return section
    }()

    private lazy var guestsSection: ConversationCreateGuestsSectionController = {
        let section = ConversationCreateGuestsSectionController(values: self.values)
        section.isHidden = true

        section.toggleAction = { [unowned self] allowGuests in
            self.values.allowGuests = allowGuests
            self.updateOptions()
        }

        return section
    }()

    private lazy var receiptsSection: ConversationCreateReceiptsSectionController = {
        let section = ConversationCreateReceiptsSectionController(values: self.values)
        section.isHidden = true

        section.toggleAction = { [unowned self] enableReceipts in
            self.values.enableReceipts = enableReceipts
            self.updateOptions()
        }

        return section
    }()

    var optionsExpanded: Bool = false {
        didSet {
            self.guestsSection.isHidden = !optionsExpanded
            self.receiptsSection.isHidden = !optionsExpanded
        }
    }

    fileprivate var navBarBackgroundView = UIView()

    fileprivate lazy var values = ConversationCreationValues(selfUser: selfUser)

    weak var delegate: ConversationCreationControllerDelegate?
    private var preSelectedParticipants: UserSet?

    convenience init() {
        self.init(preSelectedParticipants: nil, selfUser: ZMUser.selfUser())
    }

    init(preSelectedParticipants: UserSet?, selfUser: UserType) {
        self.selfUser = selfUser
        super.init(nibName: nil, bundle: nil)
        self.preSelectedParticipants = preSelectedParticipants
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.from(scheme: .contentBackground, variant: colorSchemeVariant)
        title = "conversation.create.group_name.title".localized(uppercased: true)

        setupNavigationBar()
        setupViews()

        // try to overtake the first responder from the other view
        if UIResponder.currentFirst != nil {
            nameSection.becomeFirstResponder()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameSection.becomeFirstResponder()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    private func setupViews() {
        // TODO: if keyboard is open, it should scroll.
        let collectionView = UICollectionView(forGroupedSections: ())

        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitInSuperview(safely: true)

        collectionViewController.collectionView = collectionView
        collectionViewController.sections = [nameSection, errorSection]

        if selfUser.isTeamMember {
            collectionViewController.sections.append(contentsOf: [
                optionsSection,
                guestsSection,
                receiptsSection
            ])
        }

        navBarBackgroundView.backgroundColor = UIColor.from(scheme: .barBackground, variant: colorSchemeVariant)
        view.addSubview(navBarBackgroundView)

        navBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            navBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeTopAnchor)
        ])
    }

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = UIColor.from(scheme: .textForeground, variant: colorSchemeVariant)
        self.navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: colorSchemeVariant)

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = navigationController?.closeItem()
        }

        let nextButtonItem = UIBarButtonItem(title: "general.next".localized(uppercased: true), style: .plain, target: self, action: #selector(tryToProceed))
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

    @objc fileprivate func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }

    private func updateOptions() {
        self.optionsSection.configure(with: values)
        self.guestsSection.configure(with: values)
        self.receiptsSection.configure(with: values)
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
                enableReceipts: values.enableReceipts
            )
        }
    }
}

// MARK: - SimpleTextFieldDelegate

extension ConversationCreationController: SimpleTextFieldDelegate {

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {
        errorSection.clearError()
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

// MARK: - Handlers

extension ConversationCreationController {

    private func optionsTapped(expanded: Bool) {
        guard let collectionView = collectionViewController.collectionView else {
            return
        }

        optionsExpanded = expanded

        let changes: () -> Void

        if expanded {
            nameSection.resignFirstResponder()
            changes = { collectionView.insertSections([3, 4]) }
        } else {
            changes = { collectionView.deleteSections([3, 4]) }
        }

        collectionView.performBatchUpdates(changes)
    }
}
