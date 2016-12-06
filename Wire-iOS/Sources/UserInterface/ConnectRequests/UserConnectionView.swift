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

public final class UserConnectionView: UIView, Copyable {
    
    public convenience init(instance: UserConnectionView) {
        self.init(user: instance.user)
    }

    static private var correlationFormatter: AddressBookCorrelationFormatter = {
        return AddressBookCorrelationFormatter(
            lightFont: UIFont(magicIdentifier: "style.text.small.font_spec_light"),
            boldFont: UIFont(magicIdentifier: "style.text.small.font_spec_bold"),
            color: ColorScheme.default().color(withName: ColorSchemeColorTextDimmed)
        )
    }()

    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let labelContainer = UIView()
    private let userImageView = UserImageView()
    
    public var user: ZMUser {
        didSet {
            self.updateLabelText()
            self.userImageView.user = self.user
        }
    }
    public var commonConnectionsCount: UInt = 0 {
        didSet {
            self.updateLabelText()
        }
    }

    public init(user: ZMUser) {
        self.user = user
        super.init(frame: .zero)
        
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

        firstLabel.accessibilityIdentifier = "handle"
        secondLabel.accessibilityIdentifier = "correlation"

        self.userImageView.accessibilityLabel = "user image"
        self.userImageView.shouldDesaturate = false
        self.userImageView.suggestedImageSize = .big
        self.userImageView.user = self.user
        
        [self.labelContainer, self.userImageView].forEach(self.addSubview)
        [self.firstLabel, self.secondLabel].forEach(labelContainer.addSubview)
        self.updateLabelText()
    }

    private func updateLabelText() {
        updateFirstLabelText()
        updateSecondLabelText()
    }

    private func updateFirstLabelText() {
        firstLabel.attributedText = handleLabelText ?? correlationLabelText
    }

    private func updateSecondLabelText() {
        guard nil != handleLabelText else { return }
        secondLabel.attributedText = correlationLabelText
    }

    private var handleLabelText: NSAttributedString? {
        guard let handle = user.handle else { return nil }
        return ("@" + handle) && [
            NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextDimmed),
            NSFontAttributeName: UIFont(magicIdentifier: "style.text.small.font_spec_bold")
        ]
    }

    private var correlationLabelText: NSAttributedString? {
        return type(of: self).correlationFormatter.correlationText(
            for: user,
            with: Int(commonConnectionsCount),
            addressBookName: BareUserToUser(user)?.contact()?.name
        )
    }
    
    private func createConstraints() {
        constrain(self, self.labelContainer, self.userImageView) { selfView, labelContainer, userImageView in
            labelContainer.centerX == selfView.centerX
            labelContainer.top == selfView.top
            labelContainer.left >= selfView.left

            userImageView.center == selfView.center
            userImageView.left >= selfView.left + 54
            userImageView.width == userImageView.height
            userImageView.height <= 264
        }

        constrain(labelContainer, firstLabel, secondLabel) { labelContainer, handleLabel, correlationLabel in
            handleLabel.top == labelContainer.top + 16
            handleLabel.height == 16
            correlationLabel.top == handleLabel.bottom
            handleLabel.height == 16

            [handleLabel, correlationLabel].forEach {
                $0.leading == labelContainer.leading
                $0.trailing == labelContainer.trailing
            }
        }
    }

}
