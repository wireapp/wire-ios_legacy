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
import TTTAttributedLabel
import Classy


protocol UserNameTakeOverViewControllerDelegate: NSObjectProtocol {
    func takeOverViewController(_ viewController: UserNameTakeOverViewController, didPerformAction action: UserNameTakeOverViewControllerAction)
}


enum UserNameTakeOverViewControllerAction {
    case chooseOwn(String), keepSuggestion(String), learnMore
}


final class UserNameTakeOverViewController: UIViewController {

    public var linkFont: UIFont?
    public var subtitleFont: UIFont?
    public var subtitleColor: UIColor?

    public let displayNameLabel = UILabel()
    public let suggestedHandleLabel = UILabel()
    public let titleLabel = UILabel()
    public let subtitleLabel = TTTAttributedLabel(frame: .zero)

    private let chooseOwnButton = Button(style: .full)
    private let keepSuggestedButton = Button(style: .empty, variant: .dark)
    private let contentView = UIView()
    private let topContainer = UIView()
    private let suggestedHandle: String
    private let name: String

    private let learnMore = "registration.select_handle.takeover.subtitle_link".localized
    fileprivate let learnMoreURL = URL(string:"action://learn-more")!

    weak var delegate: UserNameTakeOverViewControllerDelegate?

    init(suggestedHandle: String, name: String) {
        self.suggestedHandle = suggestedHandle
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layoutMargins = UIEdgeInsets(top: 28, left: 28, bottom: 28, right: 28)
        CASStyler.default().styleItem(self)
        setupViews()
        createConstraints()
    }

    func setupViews() {
        view.addSubview(contentView)
        [displayNameLabel, suggestedHandleLabel].forEach(topContainer.addSubview)
        [topContainer, titleLabel, subtitleLabel, chooseOwnButton, keepSuggestedButton].forEach(contentView.addSubview)
        displayNameLabel.text = name
        suggestedHandleLabel.text = "@" + suggestedHandle
        displayNameLabel.textAlignment = .center
        suggestedHandleLabel.textAlignment = .center
        titleLabel.textAlignment = .natural

        titleLabel.text = "registration.select_handle.takeover.title".localized
        chooseOwnButton.setTitle("registration.select_handle.takeover.choose_own".localized, for: .normal)
        keepSuggestedButton.setTitle("registration.select_handle.takeover.keep_suggested".localized, for: .normal)

        setupSubtitleLabel()

        [chooseOwnButton, keepSuggestedButton].forEach {
            $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
    }

    func setupSubtitleLabel() {
        subtitleLabel.textAlignment = .natural
        subtitleLabel.numberOfLines = 0
        subtitleLabel.linkAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleNone.rawValue]
        subtitleLabel.extendsLinkTouchArea = true

        guard let linkFont = linkFont, let font = subtitleFont, let color = subtitleColor else { return }
        let subtitle = "registration.select_handle.takeover.subtitle".localized
        let linkAttributes: [String: Any] = [
            NSFontAttributeName: linkFont,
            NSLinkAttributeName: learnMoreURL
        ]

        let text = (subtitle && font && color) + " " + (learnMore && linkAttributes && color)
        subtitleLabel.attributedText = text
        subtitleLabel.addLinks()
        subtitleLabel.accessibilityLabel = text.string
        subtitleLabel.delegate = self
    }

    func createConstraints() {
        constrain(displayNameLabel, suggestedHandleLabel, topContainer) { nameLabel, handleLabel, container in
            nameLabel.leading == container.leading
            nameLabel.trailing == container.trailing
            nameLabel.bottom == container.centerY - 4
            handleLabel.leading == container.leading
            handleLabel.trailing == container.trailing
            handleLabel.top == container.centerY + 4
        }

        constrain(view, contentView, topContainer, titleLabel, subtitleLabel) { view, contentView, container, titleLabel, subtitleLabel in
            contentView.edges == view.edges
            container.top == contentView.topMargin
            container.leading == contentView.leading
            container.trailing == contentView.trailing
            container.bottom == titleLabel.top
            titleLabel.leading == contentView.leadingMargin
            titleLabel.trailing == contentView.trailingMargin
            titleLabel.bottom == subtitleLabel.top - 12
            subtitleLabel.leading == contentView.leadingMargin
            subtitleLabel.trailing == contentView.trailingMargin
        }

        constrain(contentView, subtitleLabel, chooseOwnButton, keepSuggestedButton) { contentView, subtitleLabel, chooseButton, keepButton in
            subtitleLabel.bottom == chooseButton.top - 28
            chooseButton.leading == contentView.leadingMargin
            chooseButton.trailing == contentView.trailingMargin
            chooseButton.bottom == keepButton.top - 8
            chooseButton.height == 40
            keepButton.leading == contentView.leadingMargin
            keepButton.trailing == contentView.trailingMargin
            keepButton.bottom == contentView.bottomMargin
            keepButton.height == 40
        }
    }

    func buttonTapped(sender: Button) {
        guard let action = action(for: sender) else { return }
        delegate?.takeOverViewController(self, didPerformAction: action)
    }

    private func action(for button: Button) -> UserNameTakeOverViewControllerAction? {
        switch button {
        case chooseOwnButton: return .chooseOwn(suggestedHandle)
        case keepSuggestedButton: return .keepSuggestion(suggestedHandle)
        default: return nil
        }
    }

}

extension UserNameTakeOverViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        guard url == learnMoreURL else { return }
        delegate?.takeOverViewController(self, didPerformAction: .learnMore)
    }
}
