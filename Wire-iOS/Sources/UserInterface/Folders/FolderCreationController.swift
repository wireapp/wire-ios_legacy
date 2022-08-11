//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireSyncEngine

protocol FolderCreationValuesConfigurable: AnyObject {
    func configure(with name: String)
}

protocol FolderCreationControllerDelegate: AnyObject {

    func folderController(
        _ controller: FolderCreationController,
        didCreateFolder folder: LabelType)

}

final class FolderCreationController: UIViewController {

    static let mainViewHeight: CGFloat = 56
    fileprivate let colorSchemeVariant = ColorScheme.default.variant
    private let collectionViewController = SectionCollectionViewController()

    private lazy var nameSection: FolderCreationNameSectionController = {
        return FolderCreationNameSectionController(delegate: self,
                                                   conversationName: conversation.displayName)
    }()

    private var folderName: String = ""
    private var conversation: ZMConversation
    private var conversationDirectory: ConversationDirectoryType

    fileprivate var navBarBackgroundView = UIView()

    weak var delegate: FolderCreationControllerDelegate?

    public init(conversation: ZMConversation, directory: ConversationDirectoryType) {
        self.conversation = conversation
        self.conversationDirectory = directory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
        title = "folder.creation.name.title".localized(uppercased: true)

        setupNavigationBar()
        setupViews()

        // try to overtake the first responder from the other view
        if UIResponder.currentFirst != nil {
            nameSection.becomeFirstResponder()
        }
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return colorSchemeVariant == .light ? .compatibleDarkContent : .lightContent
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameSection.becomeFirstResponder()
    }

    private func setupViews() {
        // TODO: if keyboard is open, it should scroll.
        let collectionView = UICollectionView(forGroupedSections: ())

        collectionView.contentInsetAdjustmentBehavior = .never

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        collectionViewController.collectionView = collectionView
        collectionViewController.sections = [nameSection]// , errorSection]

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
        self.navigationController?.navigationBar.tintColor = SemanticColors.Label.textDefault
        self.navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: colorSchemeVariant)

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = navigationController?.closeItem()
        }

        let nextButtonItem = UIBarButtonItem(title: "folder.creation.name.button.create".localized(uppercased: true), style: .plain, target: self, action: #selector(tryToProceed))
        nextButtonItem.accessibilityIdentifier = "button.newfolder.create"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false

        navigationItem.rightBarButtonItem = nextButtonItem
    }

    func proceedWith(value: SimpleTextField.Value) {
        switch value {
        case let .error(error):
            print(error)
        case let .valid(name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            nameSection.resignFirstResponder()
            folderName = trimmed

            if let folder = ZMUserSession.shared()?.conversationDirectory.createFolder(folderName) {
                self.delegate?.folderController(self, didCreateFolder: folder)
            }
        }
    }

    @objc fileprivate func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }
}

// MARK: - SimpleTextFieldDelegate

extension FolderCreationController: SimpleTextFieldDelegate {

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {

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
