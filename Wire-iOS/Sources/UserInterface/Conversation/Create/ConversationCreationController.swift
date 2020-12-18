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
import WireDataModel

protocol ConversationCreationValuesConfigurable: class {
    func configure(with values: ConversationCreationValues)
}

final public class ConversationCreationValues {

    private var unfilteredParticipants: UserSet
    
    var allowGuests: Bool
    var enableReceipts: Bool
    var name: String
    var participants: UserSet {
        get {
            if allowGuests {
                return unfilteredParticipants
            } else {
                let selfUser = ZMUser.selfUser()
                let filteredParticipants = unfilteredParticipants.filter {
                    guard let selfUser = selfUser else { return false }
                    return $0.isOnSameTeam(otherUser: selfUser)
                }

                return UserSet(filteredParticipants)
            }
        }
        set {
            unfilteredParticipants = newValue
        }
    }
    
    init (name: String = "", participants: UserSet = UserSet(), allowGuests: Bool = true, enableReceipts: Bool = true) {
        self.name = name
        self.unfilteredParticipants = participants
        self.allowGuests = allowGuests
        self.enableReceipts = enableReceipts
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

    static let mainViewHeight: CGFloat = 56
    fileprivate let colorSchemeVariant = ColorScheme.default.variant
    
    private let collectionViewController = SectionCollectionViewController()

    private lazy var nameSection: ConversationCreateNameSectionController = {
        return ConversationCreateNameSectionController(delegate: self)
    }()
    
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

    fileprivate var values = ConversationCreationValues()

    weak var delegate: ConversationCreationControllerDelegate?
    private var preSelectedParticipants: UserSet?
    
    public convenience init(preSelectedParticipants: UserSet) {
        self.init(nibName: nil, bundle: nil)
        self.preSelectedParticipants = preSelectedParticipants
    }

    override public var prefersStatusBarHidden: Bool {
        return false
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.from(scheme: .contentBackground, variant: colorSchemeVariant)
        title = "conversation.create.group_name.title".localized(uppercased: true)
        
        setupNavigationBar()
        setupViews()
        
        // try to overtake the first responder from the other view
        if let _ = UIResponder.currentFirst {
            nameSection.becomeFirstResponder()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameSection.becomeFirstResponder()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
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
        
        if ZMUser.selfUser()?.team != nil {
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
    
    public func addParticipantsViewController(_ addParticipantsViewController: AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction) {
        switch action {
        case .updatedUsers(let users):
            values.participants = users

        case .create:
            var allParticipants = values.participants
            allParticipants.insert(ZMUser.selfUser())
            
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

