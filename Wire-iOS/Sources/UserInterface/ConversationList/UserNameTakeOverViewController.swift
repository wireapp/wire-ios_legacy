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
import WireCommonComponents

protocol UserNameTakeOverViewControllerDelegate: AnyObject {
    func takeOverViewController(_ viewController: UserNameTakeOverViewController, didPerformAction action: UserNameTakeOverViewControllerAction)
}

enum UserNameTakeOverViewControllerAction {
    case chooseOwn(String), keepSuggestion(String), learnMore
}

final class UserNameTakeOverViewController: UIViewController {

    typealias RegistrationSelectHandle = L10n.Localizable.Registration.SelectHandle.Takeover
    typealias LabelColors = SemanticColors.Label

    public let displayNameLabel = DynamicFontLabel(fontSpec: .largeThinFont,
                                                   color: LabelColors.textMessageDetails)
    public let suggestedHandleLabel = DynamicFontLabel(fontSpec: .largeFont,
                                                       color: LabelColors.textDefault)
    public let subtitleTextView = WebLinkTextView()

    private let chooseOwnButton = Button(style: .accentColorTextButtonStyle,
                                         cornerRadius: 16,
                                         fontSpec: .normalSemiboldFont)
    private let keepSuggestedButton = Button(style: .secondaryTextButtonStyle,
                                             cornerRadius: 16,
                                             fontSpec: .normalSemiboldFont)
    private let contentView = UIView()
    private let topContainer = UIView()
    private let suggestedHandle: String
    private let name: String
    private let learnMore = RegistrationSelectHandle.subtitleLink
    fileprivate let learnMoreURL = URL(string: "action://learn-more")!

    weak var delegate: UserNameTakeOverViewControllerDelegate?

    init(suggestedHandle: String, name: String) {
        self.suggestedHandle = suggestedHandle
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(contentView)
        [displayNameLabel, suggestedHandleLabel].forEach(topContainer.addSubview)
        [topContainer, subtitleTextView, chooseOwnButton, keepSuggestedButton].forEach(contentView.addSubview)

        displayNameLabel.text = name
        displayNameLabel.textAlignment = .center

        suggestedHandleLabel.text = "@" + suggestedHandle
        suggestedHandleLabel.textAlignment = .center

        chooseOwnButton.setTitle(RegistrationSelectHandle.chooseOwn, for: .normal)
        keepSuggestedButton.setTitle(RegistrationSelectHandle.keepSuggested, for: .normal)

        setupSubtitleLabel()

        [chooseOwnButton, keepSuggestedButton].forEach {
            $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
    }

    func setupSubtitleLabel() {
        subtitleTextView.textAlignment = .natural
        subtitleTextView.linkTextAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber]

        let font = FontSpec.largeThinFont.font!
        let linkFont = FontSpec.largeFont.font!
        let color = LabelColors.textDefault

        let subtitle = RegistrationSelectHandle.subtitle
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: linkFont,
            .link: learnMoreURL
        ]

        let text = (subtitle && font && color) + " " + (learnMore && linkAttributes && color)
        subtitleTextView.attributedText = text
        subtitleTextView.delegate = self
    }

    private func createConstraints() {

        [displayNameLabel, suggestedHandleLabel, topContainer, subtitleTextView, chooseOwnButton, keepSuggestedButton, contentView].prepareForLayout()

        NSLayoutConstraint.activate([
            displayNameLabel.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            displayNameLabel.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
            suggestedHandleLabel.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
            suggestedHandleLabel.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            displayNameLabel.bottomAnchor.constraint(equalTo: topContainer.centerYAnchor, constant: -4),
            suggestedHandleLabel.topAnchor.constraint(equalTo: topContainer.centerYAnchor, constant: 4)
            ])

        let inset: CGFloat = 28
        let edgeInsets = EdgeInsets(margin: inset)

        contentView.fitIn(view: view)
        NSLayoutConstraint.activate([
            topContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: edgeInsets.leading),
            topContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -edgeInsets.trailing),
            topContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: edgeInsets.top)
        ])

        NSLayoutConstraint.activate([
            topContainer.bottomAnchor.constraint(equalTo: subtitleTextView.topAnchor)
            ])

        NSLayoutConstraint.activate([
            subtitleTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: edgeInsets.leading),
            subtitleTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -edgeInsets.trailing)
        ])

        NSLayoutConstraint.activate([
            subtitleTextView.bottomAnchor.constraint(equalTo: chooseOwnButton.topAnchor, constant: -inset)
            ])

        NSLayoutConstraint.activate([
            chooseOwnButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: edgeInsets.leading),
            chooseOwnButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -edgeInsets.trailing)
        ])
        NSLayoutConstraint.activate([
            chooseOwnButton.bottomAnchor.constraint(equalTo: keepSuggestedButton.topAnchor, constant: -8),
            chooseOwnButton.heightAnchor.constraint(equalToConstant: 40)
            ])

        NSLayoutConstraint.activate([
            keepSuggestedButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: edgeInsets.leading),
            keepSuggestedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -edgeInsets.trailing),
            keepSuggestedButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -edgeInsets.bottom)
        ])

        NSLayoutConstraint.activate([
            keepSuggestedButton.heightAnchor.constraint(equalToConstant: 40)
            ])
    }

    @objc func buttonTapped(sender: LegacyButton) {
        guard let action = action(for: sender) else { return }
        delegate?.takeOverViewController(self, didPerformAction: action)
    }

    private func action(for button: LegacyButton) -> UserNameTakeOverViewControllerAction? {
        switch button {
        case chooseOwnButton: return .chooseOwn(suggestedHandle)
        case keepSuggestedButton: return .keepSuggestion(suggestedHandle)
        default: return nil
        }
    }

}

extension UserNameTakeOverViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        guard url == learnMoreURL else { return false }

        delegate?.takeOverViewController(self, didPerformAction: .learnMore)

        return false
    }

}
