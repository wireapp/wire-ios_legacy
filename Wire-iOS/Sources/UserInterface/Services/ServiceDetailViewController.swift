//
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

import WireSyncEngine
import UIKit

extension ConversationLike where Self: SwiftConversationLike {
    var botCanBeAdded: Bool {
        return conversationType != .oneOnOne &&
               teamType != nil &&
               allowServices
    }
}

struct Service {
    let serviceUser: ServiceUser
    var serviceUserDetails: ServiceDetails?
    var provider: ServiceProvider?
}

extension Service {
    init(serviceUser: ServiceUser) {
        self.serviceUser = serviceUser
        self.serviceUserDetails = nil
        self.provider = nil
    }
}

final class ServiceDetailViewController: UIViewController {

    typealias Completion = (AddBotResult?) -> Void

    enum ActionType {
        case addService(ZMConversation), removeService(ZMConversation), openConversation
    }

    var service: Service {
        didSet {
            self.detailView.service = service
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    let completion: Completion?
    weak var viewControllerDismisser: ViewControllerDismisser?

    private let detailView: ServiceDetailView
    private let actionButton: Button
    private let actionType: ActionType
    private let selfUser: UserType

    /// init method with ServiceUser, destination conversation and customized UI.
    ///
    /// - Parameters:
    ///   - serviceUser: a ServiceUser to show
    ///   - destinationConversation: the destination conversation of the serviceUser
    ///   - actionType: Enum ActionType to choose the actiion add or remove the service user
    ///   - variant: color variant
    ///   - selfUser: self user, for inject mock user for testing
    ///   - completion: completion handler
    init(serviceUser: ServiceUser,
         actionType: ActionType,
         selfUser: UserType = ZMUser.selfUser(),
         completion: Completion? = nil) {
        self.service = Service(serviceUser: serviceUser)
        self.completion = completion
        self.selfUser = selfUser

        detailView = ServiceDetailView(service: service)

        switch actionType {
        case let .addService(conversation):
            actionButton = Button.createAddServiceButton()
            actionButton.isHidden = !selfUser.canAddService(to: conversation)
        case let .removeService(conversation):
            actionButton = Button.createDestructiveServiceButton()
            actionButton.isHidden = !selfUser.canRemoveService(from: conversation)
        case .openConversation:
            actionButton = Button.openServiceConversationButton()
            actionButton.isHidden = !selfUser.canCreateService
        }

        self.actionType = actionType

        super.init(nibName: nil, bundle: nil)

        if let title = self.service.serviceUser.name {
            navigationItem.setupNavigationBarTitle(title: title.capitalized)
        }

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .cross,
                                                                 target: self,
                                                                 action: #selector(ServiceDetailViewController.dismissButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "close"
        self.navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.ServiceDetails.CloseButton.description
    }

    private func setupViews() {
        actionButton.addCallback(for: .touchUpInside, callback: callback(for: actionType, completion: self.completion))

            view.backgroundColor = .clear

        [detailView, actionButton].forEach(view.addSubview)

        createConstraints()

        guard let userSession = ZMUserSession.shared() else {
            return
        }

        self.service.serviceUser.fetchProvider(in: userSession) { [weak self] provider in
            self?.detailView.service.provider = provider
        }

        self.service.serviceUser.fetchDetails(in: userSession) { [weak self] details in
            self?.detailView.service.serviceUserDetails = details
        }
    }

    private func createConstraints() {
        [detailView, actionButton].prepareForLayout()

        NSLayoutConstraint.activate([
            detailView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            detailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(16 + UIScreen.safeArea.bottom)),
            detailView.topAnchor.constraint(equalTo: safeTopAnchor, constant: 16),
            actionButton.topAnchor.constraint(equalTo: detailView.bottomAnchor, constant: 16),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc
    func backButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func dismissButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.dismiss(animated: true, completion: { [weak self] in
            self?.completion?(nil)
        })
    }

    func callback(for type: ActionType, completion: Completion?) -> Callback<LegacyButton> {
        return { [weak self] _ in
            guard let `self` = self, let userSession = ZMUserSession.shared() else {
                return
            }
            let serviceUser = self.service.serviceUser
            switch type {
            case let .addService(conversation):
                conversation.add(serviceUser: serviceUser, in: userSession) { result in

                    switch result {
                    case .success:
                        Analytics.shared.tag(ServiceAddedEvent(service: serviceUser, conversation: conversation, context: .startUI))
                        completion?(.success(conversation: conversation))
                    case .failure(let error):
                        completion?(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                    }
                }
            case let .removeService(conversation):
                self.presentRemoveDialogue(for: serviceUser, from: conversation, dismisser: self.viewControllerDismisser)
            case .openConversation:
                if let existingConversation = ZMConversation.existingConversation(in: userSession.managedObjectContext, service: serviceUser, team: ZMUser.selfUser().team) {
                    completion?(.success(conversation: existingConversation))
                } else {
                    serviceUser.createConversation(in: userSession, completionHandler: { (result) in
                        if case let .success(conversation) = result {
                            Analytics.shared.tag(ServiceAddedEvent(service: serviceUser, conversation: conversation, context: .startUI))
                        }

                        switch result {
                        case .success(let conversation):
                            completion?(.success(conversation: conversation))
                        case .failure(let error):
                            completion?(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                        }
                    })
                }
            }
        }
    }
}

fileprivate extension Button {

    typealias PeoplePickerServices = L10n.Localizable.Peoplepicker.Services

    static func openServiceConversationButton() -> Button {
        return Button(style: .accentColorTextButtonStyle,
                      title: PeoplePickerServices.OpenConversation.item.capitalized)
    }

    static func createAddServiceButton() -> Button {
        return Button(style: .accentColorTextButtonStyle,
                      title: PeoplePickerServices.AddService.button.capitalized)
    }

    static func createDestructiveServiceButton() -> Button {
        let button = Button(style: .accentColorTextButtonStyle,
                            title: L10n.Localizable.Participants.Services.RemoveIntegration.button.capitalized)

        return button
    }

    convenience init(style: ButtonStyle, title: String) {
        self.init(style: style, cornerRadius: 16, fontSpec: .normalSemiboldFont)
        self.setTitle(title, for: .normal)
    }
}
