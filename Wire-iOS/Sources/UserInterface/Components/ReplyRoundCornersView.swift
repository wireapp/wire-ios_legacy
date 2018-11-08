//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class ReplyRoundCornersView: UIView {
    let containedView: UIView
    private let grayBoxView = UIView()
    
    init(containedView: UIView) {
        self.containedView = containedView
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.from(scheme: .replyBorder).cgColor
        layer.masksToBounds = true
        
        grayBoxView.backgroundColor = .from(scheme: .replyBorder)
        
        containedView.translatesAutoresizingMaskIntoConstraints = false
        grayBoxView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containedView)
        addSubview(grayBoxView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containedView.leadingAnchor.constraint(equalTo: grayBoxView.trailingAnchor),
            containedView.topAnchor.constraint(equalTo: topAnchor),
            containedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            grayBoxView.leadingAnchor.constraint(equalTo: leadingAnchor),
            grayBoxView.topAnchor.constraint(equalTo: topAnchor),
            grayBoxView.bottomAnchor.constraint(equalTo: bottomAnchor),
            grayBoxView.widthAnchor.constraint(equalToConstant: 4)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
