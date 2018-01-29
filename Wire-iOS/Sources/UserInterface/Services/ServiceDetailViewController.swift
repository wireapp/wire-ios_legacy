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
import Cartography

public enum ServiceConversation {
    case existing(ZMConversation)
    case new
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

extension ServiceConversation: Hashable {
    
    public static func ==(lhs: ServiceConversation, rhs: ServiceConversation) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public var hashValue: Int {
        switch self {
        case .new:
            return 0
        case .existing(let conversation):
            return conversation.hashValue
        }
    }
}

private func add(service: Service, to conversation: Any, completion: @escaping (AddBotResult)->()) {
    guard let userSession = ZMUserSession.shared(),
           let serviceConversation = conversation as? ServiceConversation else {
        return
    }
    
    func tagAdded(user: ServiceUser, to conversation: ZMConversation) {
        Analytics.shared().tag(ServiceAddedEvent(service: user, conversation: conversation, context: .startUI))
    }
    
    switch serviceConversation {
    case .new:
        userSession.startConversation(with: service.serviceUser, completion: { (result) in
            
            switch result {
            case .success(let conversation):
                tagAdded(user: service.serviceUser, to: conversation)
            default: break
            }
            
            completion(result)
        })
    case .existing(let conversation):
        conversation.add(serviceUser: service.serviceUser, in: userSession) { done in
            if let done = done {
                completion(AddBotResult.failure(error: done))
            } else {
                tagAdded(user: service.serviceUser, to: conversation)
                completion(AddBotResult.success(conversation: conversation))
            }
        }
    }
}

extension Service: Shareable {
    public typealias I = ServiceConversation
    
    public func share<ServiceConversation>(to: [ServiceConversation]) {
        guard let serviceConversation = to.first else {
            return
        }
        
        add(service: self, to: serviceConversation, completion: { result in
            
        })
    }
    
    public func share<ServiceConversation>(to: [ServiceConversation], completion: @escaping (AddBotResult)->()) {
        guard let serviceConversation = to.first else {
            return
        }
        
        add(service: self, to: serviceConversation, completion: { result in
            completion(result)
        })
    }
    
    public func previewView() -> UIView? {
        return ServiceView(service: self, variant: .dark)
    }
}

extension ServiceConversation: ShareDestination {
    public var displayName: String {
        switch self {
        case .new:
            return "peoplepicker.services.create_conversation.item".localized
        case .existing(let conversation):
            return conversation.displayName
        }
    }
    
    public var securityLevel: ZMConversationSecurityLevel {
        switch self {
        case .new:
            return ZMConversationSecurityLevel.notSecure
        case .existing(let conversation):
            return conversation.securityLevel
        }
    }
    
    public var avatarView: UIView? {
        switch self {
        case .new:
            let imageView = UIImageView()
            imageView.contentMode = .center
            imageView.image = UIImage.init(for: .plus, iconSize: .medium, color: .white)
            return imageView
        case .existing(let conversation):
            return conversation.avatarView
        }
    }
}

final class ServiceDetailViewController: UIViewController {
    private let detailView: ServiceDetailView
    private let confirmButton = Button(styleClass: "dialogue-button-full")
    
    public var service: Service {
        didSet {
            self.detailView.service = service
        }
    }
    
    public var completion: ((AddBotResult?)->())? = nil
    public var destinationConversation: ZMConversation?

    public let variant: ColorSchemeVariant
    
    init(serviceUser: ServiceUser, variant: ColorSchemeVariant) {
        self.variant = variant
        self.service = Service(serviceUser: serviceUser)
        self.detailView = ServiceDetailView(service: service, variant: variant)
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = self.service.serviceUser.name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmButton.addCallback(for: .touchUpInside) { [weak self] _ in
            self?.onAddServicePressed()
        }
        
        switch self.variant {
        case .dark:
            view.backgroundColor = .clear
        case .light:
            view.backgroundColor = .white
        }
        
        view.addSubview(detailView)
        view.addSubview(confirmButton)
        
        confirmButton.setTitle("peoplepicker.services.add_service.button".localized, for: .normal)

        var topMargin: CGFloat = 16
        if #available(iOS 11.0, *) {
            topMargin = 16
        }
        else {
            if let naviBarHeight = self.navigationController?.navigationBar.frame.height {
                topMargin = 16 + naviBarHeight
            }
        }

        constrain(self.view, detailView, confirmButton) { selfView, detailView, confirmButton in
            detailView.leading == selfView.leading + 16
            detailView.top == selfView.topMargin + topMargin

            detailView.trailing == selfView.trailing - 16
            
            confirmButton.top == detailView.bottom + 16
            confirmButton.height == 48
            confirmButton.leading == selfView.leading + 16
            confirmButton.trailing == selfView.trailing - 16
            confirmButton.bottom == selfView.bottom - 16 - UIScreen.safeArea.bottom
        }
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        if (self.navigationController?.viewControllers.count ?? 0) > 1 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(icon: .backArrow, target: self, action: #selector(ServiceDetailViewController.backButtonTapped(_:)))
        }

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .X, target: self, action: #selector(ServiceDetailViewController.dismissButtonTapped(_:)))
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
    
    private func onAddServicePressed() {
        if let conversation = self.destinationConversation {
            add(service: self.service, to: ServiceConversation.existing(conversation), completion: { [weak self] result in
                self?.completion?(result)
            })
        }
        else {
            showConversationPicker()
        }
    }
    
    private func showConversationPicker() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        
        var allConversations: [ServiceConversation] = [.new]
        
        let zmConversations = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).shareableConversations().filter { $0.conversationType != .oneOnOne }
        
        allConversations.append(contentsOf: zmConversations.map(ServiceConversation.existing))
        
        let conversationPicker = ShareServiceViewController(shareable: self.service, destinations: allConversations, showPreview: true, allowsMultiselect: false)
        conversationPicker.onServiceDismiss = { [weak self] _, completed, result in
            self?.completion?(result)
        }
        self.navigationController?.pushViewController(conversationPicker, animated: true)
    }
}
