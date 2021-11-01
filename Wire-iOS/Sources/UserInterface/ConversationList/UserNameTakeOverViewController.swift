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

protocol UserNameTakeOverViewControllerDelegate: class {
    func takeOverViewController(_ viewController: UserNameTakeOverViewController, didPerformAction action: UserNameTakeOverViewControllerAction)
}

enum UserNameTakeOverViewControllerAction {
    case chooseOwn(String), keepSuggestion(String), learnMore
}

final class UserNameTakeOverViewController: UIViewController {

    public let displayNameLabel = UILabel()
    public let suggestedHandleLabel = UILabel()
    public let subtitleTextView = WebLinkTextView()

    private let chooseOwnButton = Button(style: .full)
    private let keepSuggestedButton = Button(style: .empty, variant: .dark)
    private let contentView = UIView()
    private let topContainer = UIView()
    private let suggestedHandle: String
    private let name: String

    private let learnMore = "registration.select_handle.takeover.subtitle_link".localized
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
        view.backgroundColor = UIColor.clear
        view.addSubview(contentView)
        [displayNameLabel, suggestedHandleLabel].forEach(topContainer.addSubview)
        [topContainer, subtitleTextView, chooseOwnButton, keepSuggestedButton].forEach(contentView.addSubview)

        displayNameLabel.font = FontSpec(.large, .thin).font!
        displayNameLabel.textColor = UIColor.from(scheme: .textDimmed, variant: .light)
        displayNameLabel.text = name
        displayNameLabel.textAlignment = .center

        suggestedHandleLabel.font = FontSpec(.large, .none).font!
        suggestedHandleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
        suggestedHandleLabel.text = "@" + suggestedHandle
        suggestedHandleLabel.textAlignment = .center

        chooseOwnButton.setTitle("registration.select_handle.takeover.choose_own".localized, for: .normal)
        keepSuggestedButton.setTitle("registration.select_handle.takeover.keep_suggested".localized, for: .normal)

        setupSubtitleLabel()

        [chooseOwnButton, keepSuggestedButton].forEach {
            $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
    }

    func setupSubtitleLabel() {
        subtitleTextView.textAlignment = .natural
        subtitleTextView.linkTextAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber]

        let font = FontSpec(.large, .thin).font!
        let linkFont = FontSpec(.large, .none).font!
        let color = UIColor.from(scheme: .textForeground, variant: .dark)

        let subtitle = "registration.select_handle.takeover.subtitle".localized
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: linkFont,
            .link: learnMoreURL
        ]

        let text = (subtitle && font && color) + " " + (learnMore && linkAttributes && color)
        subtitleTextView.attributedText = text
        subtitleTextView.accessibilityLabel = text.string
        subtitleTextView.delegate = self
    }

    func createConstraints() {

        [displayNameLabel, suggestedHandleLabel, topContainer, subtitleTextView, chooseOwnButton, keepSuggestedButton, contentView].prepareForLayout()

        displayNameLabel.fitInSuperview(exclude: [.top, .bottom])
        suggestedHandleLabel.fitInSuperview(exclude: [.top, .bottom])

        NSLayoutConstraint.activate([
            displayNameLabel.bottomAnchor.constraint(equalTo: topContainer.centerYAnchor, constant: -4),
            suggestedHandleLabel.topAnchor.constraint(equalTo: topContainer.centerYAnchor, constant: 4)
            ])

        let inset: CGFloat = 28
        let edgeInsets = EdgeInsets(margin: inset)

        contentView.fitInSuperview()
        topContainer.fitInSuperview(with: edgeInsets, exclude: [.bottom])

        NSLayoutConstraint.activate([
            topContainer.bottomAnchor.constraint(equalTo: subtitleTextView.topAnchor)
            ])

        subtitleTextView.fitInSuperview(with: edgeInsets, exclude: [.top, .bottom])

        NSLayoutConstraint.activate([
            subtitleTextView.bottomAnchor.constraint(equalTo: chooseOwnButton.topAnchor, constant: -inset)
            ])

        chooseOwnButton.fitInSuperview(with: edgeInsets, exclude: [.top, .bottom])
        NSLayoutConstraint.activate([
            chooseOwnButton.bottomAnchor.constraint(equalTo: keepSuggestedButton.topAnchor, constant: -8),
            chooseOwnButton.heightAnchor.constraint(equalToConstant: 40)
            ])

        keepSuggestedButton.fitInSuperview(with: edgeInsets, exclude: [.top])

        NSLayoutConstraint.activate([
            keepSuggestedButton.heightAnchor.constraint(equalToConstant: 40)
            ])
    }

    @objc func buttonTapped(sender: Button) {
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

extension UserNameTakeOverViewController: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        guard url == learnMoreURL else { return false }

        delegate?.takeOverViewController(self, didPerformAction: .learnMore)

        return false
    }

}
