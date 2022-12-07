//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class IncomingCallActionsView: UIView {
    weak var delegate: CallingActionsViewDelegate?

    private let horizontalStackView = UIStackView(axis: .horizontal)
    private let endCallButton =  EndCallButton.endCallButton()
    private let pickUpButton =  PickUpButton.pickUpButton()

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.from(scheme: .callActionBackground, variant: ColorScheme.default.variant)
        horizontalStackView.distribution = .fill
        addSubview(horizontalStackView)
        let springView = UIView()
        springView.setContentCompressionResistancePriority(.required, for: .vertical)
        [endCallButton, springView, pickUpButton].forEach(horizontalStackView.addArrangedSubview)
        endCallButton.addTarget(self, action: #selector(endCall), for: .touchUpInside)
        pickUpButton.addTarget(self, action: #selector(pickUp), for: .touchUpInside)
        pickUpButton.subtitleTransformLabel.font = FontSpec(.small, .bold).font!
        endCallButton.subtitleTransformLabel.font = FontSpec(.small, .bold).font!
    }

    private func createConstraints() {
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            endCallButton.trailingAnchor.constraint(equalTo:endCallButton.leadingAnchor, constant: 180),
//            pickUpButton.widthAnchor.constraint(equalToConstant: 80).withPriority(.required)
        ])
    }

    @objc private func pickUp() {
        delegate?.callingActionsViewPerformAction(.acceptCall)
    }

    @objc private func endCall() {
        delegate?.callingActionsViewPerformAction(.terminateCall)
    }

}
