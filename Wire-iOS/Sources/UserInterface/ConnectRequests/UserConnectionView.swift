//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel
import UIKit
import WireSyncEngine

final class UserConnectionView: UIView, Copyable {

    public convenience init(instance: UserConnectionView) {
        self.init(user: instance.user)
    }

    static private var correlationFormatter: AddressBookCorrelationFormatter = {
        return AddressBookCorrelationFormatter(
            lightFont: FontSpec(.small, .light).font!,
            boldFont: FontSpec(.small, .medium).font!,
            color: UIColor.from(scheme: .textDimmed)
        )
    }()

    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let labelContainer = UIView()
    private let userImageView = UserImageView()

    public var user: UserType {
        didSet {
            self.updateLabels()
            self.userImageView.user = self.user
        }
    }

    public init(user: UserType) {
        self.user = user
        super.init(frame: .zero)
        self.userImageView.userSession = ZMUserSession.shared()
        self.setup()
        self.createConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        [firstLabel, secondLabel].forEach {
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }

        self.userImageView.accessibilityLabel = "user image"
        self.userImageView.size = .big
        self.userImageView.user = self.user

        [self.labelContainer, self.userImageView].forEach(self.addSubview)
        [self.firstLabel, self.secondLabel].forEach(labelContainer.addSubview)
        self.updateLabels()
    }

    private func updateLabels() {
        updateFirstLabel()
        updateSecondLabel()
    }

    private func updateFirstLabel() {
        if let handleText = handleLabelText {
            firstLabel.attributedText = handleText
            firstLabel.accessibilityIdentifier = "username"
        } else {
            firstLabel.attributedText = correlationLabelText
            firstLabel.accessibilityIdentifier = "correlation"
        }
    }

    private func updateSecondLabel() {
        guard nil != handleLabelText else { return }
        secondLabel.attributedText = correlationLabelText
        secondLabel.accessibilityIdentifier = "correlation"
    }

    private var handleLabelText: NSAttributedString? {
        guard let handle = user.handle, handle.count > 0 else { return nil }
        return ("@" + handle) && [
            .foregroundColor: UIColor.from(scheme: .textDimmed),
            .font: FontSpec(.small, .semibold).font!
        ]
    }

    private var correlationLabelText: NSAttributedString? {
        return type(of: self).correlationFormatter.correlationText(
            for: user,
            addressBookName: (user as? ZMUser)?.addressBookEntry?.cachedName
        )
    }

    private func createConstraints() {
        constrain(self, self.labelContainer, self.userImageView) { selfView, labelContainer, userImageView in
            labelContainer.centerX == selfView.centerX
            labelContainer.top == selfView.top
            labelContainer.left >= selfView.left

            userImageView.top >= labelContainer.bottom
            userImageView.center == selfView.center
            userImageView.left >= selfView.left + 54
            userImageView.width == userImageView.height
            userImageView.height <= 264
            userImageView.bottom <= selfView.bottom
        }

        let verticalMargin = CGFloat(16)

        constrain(labelContainer, firstLabel, secondLabel) { labelContainer, handleLabel, correlationLabel in
            handleLabel.top == labelContainer.top + verticalMargin
            handleLabel.height == 16
            correlationLabel.top == handleLabel.bottom
            handleLabel.height == 16
            correlationLabel.bottom == labelContainer.bottom - verticalMargin

            [handleLabel, correlationLabel].forEach {
                $0.leading == labelContainer.leading
                $0.trailing == labelContainer.trailing
            }
        }
    }

}
