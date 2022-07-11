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
import UIKit
import WireCommonComponents

final class ServiceDetailView: UIView {
    private let serviceView: ServiceView
    private let descriptionTextView = UITextView()

    public let variant: ColorSchemeVariant

    public var service: Service {
        didSet {
            updateForService()
            serviceView.service = self.service
        }
    }

    init(service: Service, variant: ColorSchemeVariant) {
        self.service = service
        self.variant = variant
        self.serviceView = ServiceView(service: service, variant: variant)
        super.init(frame: .zero)

        [serviceView, descriptionTextView].forEach(addSubview)

        createConstraints()

        switch variant {
        case .dark:
            backgroundColor = .clear
        case .light:
            backgroundColor = .white
        }

        descriptionTextView.backgroundColor = .clear
        descriptionTextView.textContainerInset = .zero
        descriptionTextView.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        descriptionTextView.font = FontSpec(.normal, .light).font
        descriptionTextView.isEditable = false
        updateForService()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [self, serviceView, descriptionTextView].prepareForLayout()

        NSLayoutConstraint.activate([
            serviceView.leadingAnchor.constraint(equalTo: leadingAnchor),
            serviceView.trailingAnchor.constraint(equalTo: trailingAnchor),
            serviceView.topAnchor.constraint(equalTo: topAnchor),
            descriptionTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: bottomAnchor),
            descriptionTextView.topAnchor.constraint(equalTo: serviceView.bottomAnchor, constant: 16)])
    }

    private func updateForService() {
        descriptionTextView.text = service.serviceUserDetails?.serviceDescription
    }
}

final class ServiceView: UIView {
    private let logoView = UserImageView(size: .normal)
    private let nameLabel = UILabel()
    private let providerLabel = UILabel()

    public let variant: ColorSchemeVariant

    public var service: Service {
        didSet {
            updateForService()
        }
    }

    init(service: Service, variant: ColorSchemeVariant) {
        self.service = service
        self.variant = variant
        super.init(frame: .zero)
        [logoView, nameLabel, providerLabel].forEach(addSubview)

        createConstraints()

        backgroundColor = .clear

        nameLabel.font = FontSpec(.large, .regular).font
        nameLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        nameLabel.backgroundColor = .clear

        providerLabel.font = FontSpec(.medium, .regular).font
        providerLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
        providerLabel.backgroundColor = .clear
        updateForService()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        self.translatesAutoresizingMaskIntoConstraints = false
        logoView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        providerLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // logoView
            logoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            logoView.topAnchor.constraint(equalTo: topAnchor),
            logoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 80),

            // nameLabel
            nameLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: topAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // providerLabel
            providerLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 16),
            providerLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            providerLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func updateForService() {
        logoView.user = service.serviceUser
        nameLabel.text = service.serviceUser.name
        providerLabel.text = service.provider?.name
    }
}
