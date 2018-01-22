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

private func add(service: Service, to conversation: Any) {
    guard let userSession = ZMUserSession.shared(),
           let serviceConversation = conversation as? ServiceConversation else {
        return
    }
    
    switch serviceConversation {
    case .new:
        userSession.startConversation(with: service.serviceUser) { conversation in
            
        }
    case .existing(let conversation):
        conversation.add(serviceUser: service.serviceUser, in: userSession) { done in
            
        }
    }
}

extension Service: Shareable {
    public typealias I = ServiceConversation
    
    public func share<ServiceConversation>(to: [ServiceConversation]) {
        guard let serviceConversation = to.first else {
            return
        }
        
        add(service: self, to: serviceConversation)
    }
    
    public func previewView() -> UIView? {
        return ServiceView(service: self)
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
    
    public var completion: ((ZMConversation?)->())? = nil // TODO: not wired up yet
    
    init(serviceUser: ServiceUser) {
        self.service = Service(serviceUser: serviceUser)
        self.detailView = ServiceDetailView(service: service)
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = self.service.serviceUser.name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmButton.addCallback(for: .touchUpInside) { [weak self] _ in
            self?.showConversationPicker()
        }
        
        view.backgroundColor = .clear
        view.addSubview(detailView)
        view.addSubview(confirmButton)
        
        confirmButton.setTitle("peoplepicker.services.add_service.button".localized, for: .normal)

        var topMargin: CGFloat = 16
        if #available(iOS 10.0, *) {
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
    }
    
    private func showConversationPicker() {
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        
        var allConversations: [ServiceConversation] = [.new]
        
        let zmConversations = ZMConversationList.conversationsIncludingArchived(inUserSession: userSession).shareableConversations()
        
        allConversations.append(contentsOf: zmConversations.map(ServiceConversation.existing))
        
        let conversationPicker = ShareViewController<ServiceConversation, Service>(shareable: self.service, destinations: allConversations, showPreview: true, allowsMultiselect: false)
        conversationPicker.onDismiss = { [weak self] _, completed in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
        self.navigationController?.pushViewController(conversationPicker, animated: true)
    }
}
