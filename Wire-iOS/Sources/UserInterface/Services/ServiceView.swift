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

final class ServiceDetailView: UIView {
    private let serviceView: ServiceView
    private let descriptionTextView = UITextView()
    
    public var service: Service {
        didSet {
            updateForService()
            serviceView.service = self.service
        }
    }
    
    init(service: Service) {
        self.service = service
        self.serviceView = ServiceView(service: service)
        super.init(frame: .zero)

        [serviceView, descriptionTextView].forEach(addSubview)

        constrain(self, serviceView, descriptionTextView) { selfView, serviceView, descriptionTextView in
            serviceView.top == selfView.top
            serviceView.leading == selfView.leading
            serviceView.trailing == selfView.trailing
            
            descriptionTextView.top == serviceView.bottom
            descriptionTextView.leading == selfView.leading
            descriptionTextView.trailing == selfView.trailing
            descriptionTextView.bottom == selfView.bottom
        }
        
        backgroundColor = .clear
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.textColor = .white
        descriptionTextView.font = FontSpec(.normal, .regular).font
        descriptionTextView.isEditable = false
        updateForService()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateForService() {
        descriptionTextView.text = service.serviceUserDetails?.serviceDescription
    }
}

final class ServiceView: UIView {
    private let logoView = UserImageView(size: .big)
    private let nameLabel = UILabel()
    private let providerLabel = UILabel()
    
    public var service: Service {
        didSet {
            updateForService()
        }
    }
    
    init(service: Service) {
        self.service = service
        super.init(frame: .zero)
        [logoView, nameLabel, providerLabel].forEach(addSubview)
        constrain(self, logoView, nameLabel, providerLabel) { selfView, logoView, nameLabel, providerLabel in
            logoView.leading == selfView.leading
            logoView.top == selfView.top
            logoView.bottom == selfView.bottom
            
            logoView.width == 80
            logoView.height == logoView.width
            
            nameLabel.leading == logoView.trailing + 16
            nameLabel.top == selfView.top
            nameLabel.trailing == selfView.trailing
            
            providerLabel.leading == logoView.trailing + 16
            providerLabel.top == nameLabel.bottom + 8
            providerLabel.trailing == selfView.trailing
        }
        
        backgroundColor = .clear
        
        nameLabel.font = FontSpec(.large, .regular).font
        nameLabel.textColor = .white
        nameLabel.backgroundColor = .clear
        
        providerLabel.font = FontSpec(.medium, .regular).font
        providerLabel.textColor = .white
        providerLabel.backgroundColor = .clear
        updateForService()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateForService() {
        logoView.user = service.serviceUser as? (ZMSearchUser & AccentColorProvider)
        nameLabel.text = service.serviceUser.name
        providerLabel.text = service.provider?.name
    }
}
