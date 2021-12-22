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

final class TeamMemberInviteHeaderView: UIView {

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let bottomSpacerView = UIView()
    private var bottomSpacerViewHeightConstraint: NSLayoutConstraint?

    var header: UIView {
        return titleLabel
    }

    var bottomSpacing: CGFloat = 0 {
        didSet {
            bottomSpacerViewHeightConstraint?.constant = bottomSpacing
        }
    }

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        subtitleLabel.font = FontSpec(.normal, .regular).font!
        stackView.axis = .vertical
        stackView.spacing = 24

        [titleLabel, subtitleLabel, bottomSpacerView].forEach(stackView.addArrangedSubview)

        [titleLabel, subtitleLabel].forEach {
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        }

        titleLabel.textColor = UIColor.Team.textColor
        subtitleLabel.textColor = UIColor.Team.subtitleColor
        addSubview(stackView)

        titleLabel.text = "team.invite.header.title".localized
        subtitleLabel.text = "team.invite.header.subtitle".localized
    }

    func updateHeadlineLabelFont(forWidth width: CGFloat) {
        titleLabel.font = width > CGFloat.iPhone4Inch.width ? AuthenticationStepController.headlineFont : AuthenticationStepController.headlineSmallFont
    }

    private func createConstraints() {
        [stackView, bottomSpacerView].prepareForLayout()
        stackView.fitInSuperview()

        bottomSpacerViewHeightConstraint = bottomSpacerView.heightAnchor.constraint(equalToConstant: 0)
        bottomSpacerViewHeightConstraint?.priority = .fittingSizeLevel
        bottomSpacerViewHeightConstraint?.isActive = true
    }
}
