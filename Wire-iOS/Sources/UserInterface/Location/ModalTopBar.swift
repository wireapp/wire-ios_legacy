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


import Cartography

protocol ModalTopBarDelegate: class {
    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar)
}

final class ModalTopBar: UIView {

    let dismissButton = IconButton()

    public let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .from(scheme: .textForeground)
        label.textAlignment = .center
        label.accessibilityIdentifier = "Title"

        return label
    }()

    public let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .from(scheme: .textForeground)
        label.font = UIFont.systemFont(ofSize: 11)
        label.textAlignment = .center
        label.accessibilityIdentifier = "Subtitle"

        return label
    }()

    public let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(scheme: .separator)
        return view
    }()

    public let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.axis = .vertical

        return stack
    }()

    weak var delegate: ModalTopBarDelegate?
    private var contentTopConstraint: NSLayoutConstraint?

    private var title: String? {
        didSet {
            titleLabel.text = title?.localizedUppercase
            titleLabel.isHidden = title == nil
            titleLabel.accessibilityLabel = title
            titleLabel.accessibilityTraits.insert(.header)
        }
    }

    private var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle?.localizedUppercase
            subtitleLabel.isHidden = subtitle == nil
            subtitleLabel.accessibilityLabel = subtitle
        }
    }

    private var sepeatorHeight: NSLayoutConstraint!

    var needsSeparator: Bool = true {
        didSet {
            sepeatorHeight.constant = needsSeparator ? 1 : 0
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        createConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String?, topAnchor: NSLayoutYAxisAnchor) {
        if let topConstraint = self.contentTopConstraint {
            contentStackView.removeConstraint(topConstraint)
        }

        contentTopConstraint = contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4)
        contentTopConstraint?.isActive = true

        self.title = title
        self.subtitle = subtitle
        self.titleLabel.font = subtitle == nil ? .mediumSemiboldFont : .systemFont(ofSize: 11, weight: .semibold)
    }

    fileprivate func configureViews() {
        backgroundColor = .from(scheme: .background)
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        [titleLabel, subtitleLabel].forEach(contentStackView.addArrangedSubview)
        [contentStackView, dismissButton, separatorView].forEach(addSubview)

        dismissButton.accessibilityIdentifier = "Close"
        dismissButton.accessibilityLabel = "general.close".localized

        dismissButton.setIcon(.cross, size: .tiny, for: [])
        dismissButton.setIconColor(.from(scheme: .iconNormal), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.hitAreaPadding = CGSize(width: 20, height: 20)
    }

    fileprivate func createConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        sepeatorHeight = separatorView.heightAnchor.constraint(equalToConstant: 1)

        NSLayoutConstraint.activate([
            // contentStackView
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: safeLeadingAnchor, constant: 48),
            contentStackView.centerXAnchor.constraint(equalTo: safeCenterXAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: dismissButton.leadingAnchor, constant: -12),
            contentStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            // dismissButton
            dismissButton.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -16),
            dismissButton.centerYAnchor.constraint(equalTo: contentStackView.centerYAnchor),

            // separator
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sepeatorHeight
        ])

        dismissButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }

    @objc fileprivate func dismissButtonTapped(_ sender: IconButton) {
        delegate?.modelTopBarWantsToBeDismissed(self)
    }

}
