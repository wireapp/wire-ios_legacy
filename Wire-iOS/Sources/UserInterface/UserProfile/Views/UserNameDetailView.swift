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


import UIKit
import Cartography
 import WireDataModel

fileprivate let smallLightFont = FontSpec(.small, .light).font!
fileprivate let smallBoldFont = FontSpec(.small, .medium).font!
fileprivate let normalBoldFont = FontSpec(.normal, .medium).font!

final class AddressBookCorrelationFormatter: NSObject {

    let lightFont, boldFont: UIFont
    let color: UIColor

    init(lightFont: UIFont, boldFont: UIFont, color: UIColor) {
        self.lightFont = lightFont
        self.boldFont = boldFont
        self.color = color
    }

    private func addressBookText(for user: UserType, with addressBookName: String) -> NSAttributedString? {
        guard !user.isSelfUser, let userName = user.name else { return nil }
        let suffix = "conversation.connection_view.in_address_book".localized && lightFont && color
        if addressBookName.lowercased() == userName.lowercased() {
            return suffix
        }

        let contactName = addressBookName && boldFont && color
        return contactName + " " + suffix
    }

    func correlationText(for user: UserType, addressBookName: String?) -> NSAttributedString? {
        if let name = addressBookName, let addressBook = addressBookText(for: user, with: name) {
            return addressBook
        }

        return nil
    }

}


final class UserNameDetailViewModel: NSObject {

    let title: NSAttributedString

    private let handleText: NSAttributedString?
    private let correlationText: NSAttributedString?

    var firstSubtitle: NSAttributedString? {
        return handleText ?? correlationText
    }

    var secondSubtitle: NSAttributedString? {
        guard nil != handleText else { return nil }
        return correlationText
    }

    var firstAccessibilityIdentifier: String? {
        if nil != handleText {
            return "username"
        } else if nil != correlationText {
            return "correlation"
        }

        return nil
    }

    var secondAccessibilityIdentifier: String? {
        guard nil != handleText && nil != correlationText else { return nil }
        return "correlation"
    }

    static var formatter: AddressBookCorrelationFormatter = {
        AddressBookCorrelationFormatter(lightFont: smallLightFont, boldFont: smallBoldFont, color: UIColor.from(scheme: .textDimmed))
    }()

    init(user: UserType?, fallbackName fallback: String, addressBookName: String?) {
        title = UserNameDetailViewModel.attributedTitle(for: user, fallback: fallback)
        handleText = UserNameDetailViewModel.attributedSubtitle(for: user)
        correlationText = UserNameDetailViewModel.attributedCorrelationText(for: user, addressBookName: addressBookName)
    }

    static func attributedTitle(for user: UserType?, fallback: String) -> NSAttributedString {
        return (user?.name ?? fallback) && normalBoldFont && UIColor.from(scheme: .textForeground)
    }

    static func attributedSubtitle(for user: UserType?) -> NSAttributedString? {
        guard let handle = user?.handle, handle.count > 0 else { return nil }
        return ("@" + handle) && smallBoldFont && UIColor.from(scheme: .textDimmed)
    }

    static func attributedCorrelationText(for user: UserType?, addressBookName: String?) -> NSAttributedString? {
        guard let user = user else { return nil }
        return formatter.correlationText(for: user, addressBookName: addressBookName)
    }
}


final class UserNameDetailView: UIView {

    let subtitleLabel = UILabel()
    let correlationLabel = UILabel()

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: UserNameDetailViewModel) {
        subtitleLabel.attributedText = model.firstSubtitle
        correlationLabel.attributedText = model.secondSubtitle

        subtitleLabel.accessibilityIdentifier = model.firstAccessibilityIdentifier
        correlationLabel.accessibilityIdentifier = model.secondAccessibilityIdentifier
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        [subtitleLabel, correlationLabel].forEach {
            $0.textAlignment = .center
            $0.backgroundColor = .clear
            addSubview($0)
        }
    }

    private func createConstraints() {
        constrain(self, subtitleLabel, correlationLabel) { view, subtitle, correlation in
            subtitle.top == view.top
            subtitle.centerX == view.centerX
            subtitle.height == 16

            correlation.top == subtitle.bottom
            correlation.centerX == view.centerX
            correlation.height == 16
            correlation.bottom == view.bottom
        }
    }

}
