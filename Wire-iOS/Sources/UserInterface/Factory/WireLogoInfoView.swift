// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class WireLogoInfoView: UIView {
    let contentView = UIView()

    let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundDefault
        return view
    }()

    let progressContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 40
        view.backgroundColor = UIColor(red: 50/255, green: 54/255, blue: 57/255, alpha: 1)
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 5
        view.layer.shadowOpacity = 0.29
        view.layer.shadowColor = UIColor.black.cgColor
        view.accessibilityIdentifier = "ProgressView"
        return view
    }()

    let wireLogo: UIImageView = {
        let logo = UIImageView(image: UIImage(named: "wire-logo-letter"))
        logo.accessibilityIdentifier = "ProgressView.Logo"
        return logo
    }()

    let titleLabel: UILabel = {
        let label = DynamicFontLabel(fontSpec: .largeSemiboldFont,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.accessibilityValue = label.text
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = DynamicFontLabel(fontSpec: .normalRegularFont,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityValue = label.text
        return label
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        subtitleLabel.text = subtitle

        configureSubviews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        addSubview(headerView)

        contentView.addSubview(progressContainerView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        progressContainerView.addSubview(wireLogo)

        addSubview(contentView)
    }

    private func createConstraints() {
        [headerView,
         contentView,
         progressContainerView,
         wireLogo,
         titleLabel,
         subtitleLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            // header view
            headerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3, constant: 0),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.bottomAnchor.constraint(equalTo: contentView.topAnchor),

            // content view
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // progress container view
            progressContainerView.centerYAnchor.constraint(equalTo: contentView.topAnchor),
            progressContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressContainerView.widthAnchor.constraint(equalToConstant: 80),
            progressContainerView.heightAnchor.constraint(equalToConstant: 80),

            // wire logo
            wireLogo.centerYAnchor.constraint(equalTo: progressContainerView.centerYAnchor),
            wireLogo.centerXAnchor.constraint(equalTo: progressContainerView.centerXAnchor),

            // title label
            titleLabel.topAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)])
    }

}
