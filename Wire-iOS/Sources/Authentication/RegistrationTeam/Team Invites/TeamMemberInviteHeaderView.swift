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

final class TeamMemberInviteHeaderView: UIView {
    
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let bottomSpacerView = UIView()
    private var bottomSpacerViewHeightConstraint: NSLayoutConstraint?
    
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        subtitleLabel.font = FontSpec(.normal, .regular).font!
        titleLabel.text = "team.invite.header.title".localized
        subtitleLabel.text = "team.invite.header.subtitle".localized
        stackView.axis = .vertical
        stackView.spacing = 24
        [titleLabel, subtitleLabel, bottomSpacerView].forEach(stackView.addArrangedSubview)
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.Team.textColor
        subtitleLabel.textColor = UIColor.Team.subtitleColor
        addSubview(stackView)
    }
    
    func updateHeadlineLabelFont(forWidth width: CGFloat) {
        titleLabel.font = width > 320 ? TeamCreationStepController.headlineFont : TeamCreationStepController.headlineSmallFont
    }
    
    private func createConstraints() {
        constrain(self, stackView, bottomSpacerView) { view, stackView, bottomSpacerView in
            stackView.edges == view.edges
            bottomSpacerViewHeightConstraint = bottomSpacerView.height == 0
        }
    }
}
