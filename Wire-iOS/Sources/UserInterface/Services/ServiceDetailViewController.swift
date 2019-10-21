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

import Foundation

extension ZMConversation {
    var botCanBeAdded: Bool {
        return self.conversationType != .oneOnOne && self.team != nil && self.allowGuests
    }
}

public struct Service {
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

struct ServiceDetailVariant {
    let colorScheme: ColorSchemeVariant
    let opaque: Bool
}

final class ServiceDetailViewController: UIViewController {

    typealias Completion = (AddBotResult?) -> Void

    enum ActionType {
        case addService(ZMConversation), removeService(ZMConversation), openConversation
    }

    public var service: Service {
        didSet {
            self.detailView.service = service
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    public let completion: Completion?
    public let variant: ServiceDetailVariant
    public weak var viewControllerDismisser: ViewControllerDismisser?

    private let detailView: ServiceDetailView
    private let actionButton: Button
    private let actionType: ActionType

    /// init method with ServiceUser, destination conversation and customized UI.
    ///
    /// - Parameters:
    ///   - serviceUser: a ServiceUser to show
    ///   - destinationConversation: the destination conversation of the serviceUser
    ///   - actionType: Enum ActionType to choose the actiion add or remove the service user
    ///   - variant: color variant
    init(serviceUser: ServiceUser,
         actionType: ActionType,
         variant: ServiceDetailVariant,
         completion: Completion? = nil) {
        self.service = Service(serviceUser: serviceUser)
        self.completion = completion
        detailView = ServiceDetailView(service: service, variant: variant.colorScheme)

        switch actionType {
        case let .addService(conversation):
            actionButton = Button.createAddServiceButton()
            actionButton.isHidden = !ZMUser.selfUser().canAddService(to: conversation)
        case let .removeService(conversation):
            actionButton = Button.createDestructiveServiceButton()
            actionButton.isHidden = !ZMUser.selfUser().canRemoveService(from: conversation)
        case .openConversation:
            actionButton = Button.openServiceConversationButton()
            actionButton.isHidden = !ZMUser.selfUser().canCreateService
        }

        self.variant = variant
        self.actionType = actionType

        super.init(nibName: nil, bundle: nil)

        self.title = self.service.serviceUser.name?.localizedUppercase

        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        actionButton.addCallback(for: .touchUpInside, callback: callback(for: actionType, completion: self.completion))

        if variant.opaque {
            view.backgroundColor = UIColor.from(scheme: .background, variant: self.variant.colorScheme)
        } else {
            view.backgroundColor = .clear
        }

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
        [detailView, actionButton].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        detailView.fitInSuperview(with: EdgeInsets(margin: 16), exclude: [.top, .bottom])

        actionButton.fitInSuperview(with: EdgeInsets(top: 0, leading: 16, bottom: 16 + UIScreen.safeArea.bottom, trailing: 16), exclude: [.top])

        NSLayoutConstraint.activate([
            detailView.topAnchor.constraint(equalTo: safeTopAnchor, constant: 16),
            actionButton.topAnchor.constraint(equalTo: detailView.bottomAnchor, constant: 16),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
            ])
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .cross,
                                                                 target: self,
                                                                 action: #selector(ServiceDetailViewController.dismissButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "close"
    }

    @objc(backButtonTapped:)
    public func backButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc(dismissButtonTapped:)
    public func dismissButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.dismiss(animated: true, completion: { [weak self] in
            self?.completion?(nil)
        })
    }

    func callback(for type: ActionType, completion: Completion?) -> Callback<Button> {
        return { [weak self] _ in
            guard let `self` = self, let userSession = ZMUserSession.shared() else {
                return
            }
            let serviceUser = self.service.serviceUser
            switch type {
            case let .addService(conversation):
                conversation.add(serviceUser: serviceUser, in: userSession) { error in
                    if let error = error {
                        completion?(.failure(error: error))
                    } else {
                        Analytics.shared().tag(ServiceAddedEvent(service: serviceUser, conversation: conversation, context: .startUI))
                        completion?(.success(conversation: conversation))
                    }
                }
            case let .removeService(conversation):
                guard let user = serviceUser as? ZMUser else { return }
                self.presentRemoveDialogue(for: user, from: conversation, dismisser: self.viewControllerDismisser)
            case .openConversation:
                if let existingConversation = ZMConversation.existingConversation(in: userSession.managedObjectContext, service: serviceUser, team: ZMUser.selfUser().team) {
                    completion?(.success(conversation: existingConversation))
                } else {
                    userSession.startConversation(with: serviceUser) { result in
                        if case let .success(conversation) = result {
                            Analytics.shared().tag(ServiceAddedEvent(service: serviceUser, conversation: conversation, context: .startUI))
                        }
                        completion?(result)
                    }
                }
            }
        }
    }
}

fileprivate extension Button {

    static func openServiceConversationButton() -> Button {
        return Button(style: .full, title: "peoplepicker.services.open_conversation.item".localized)
    }

    static func createAddServiceButton() -> Button {
        return Button(style: .full, title: "peoplepicker.services.add_service.button".localized)
    }

    static func createDestructiveServiceButton() -> Button {
        let button = Button(style: .full, title: "participants.services.remove_integration.button".localized)
        button.setBackgroundImageColor(.vividRed, for: .normal)
        return button
    }

    convenience init(style: ButtonStyle, title:String) {
        self.init(style: style)
        setTitle(title, for: .normal)
    }
}
