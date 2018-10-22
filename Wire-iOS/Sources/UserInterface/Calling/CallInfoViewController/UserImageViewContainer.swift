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

final class UserImageViewContainer: UIView {
    private let userImageView: UserImageView
    private let maxSize: CGFloat
    private let yOffset: CGFloat
    
    var user: UserType? {
        didSet {
            userImageView.user = user
        }
    }
    
    init(size: UserImageView.Size, maxSize: CGFloat, yOffset: CGFloat) {
        userImageView = UserImageView(size: size)
        self.maxSize = maxSize
        self.yOffset = yOffset
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        userImageView.isAccessibilityElement = false
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userImageView)
        
        let priority: Float = 249
        userImageView.setContentHuggingPriority(UILayoutPriority(rawValue: priority), for: .vertical)
        userImageView.setContentHuggingPriority(UILayoutPriority(rawValue: priority), for: .horizontal)
        userImageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: priority), for: .vertical)
        userImageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: priority), for: .horizontal)
        
        userImageView.setImageConstraint(resistance: priority, hugging: priority)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            userImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: yOffset),
            userImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            userImageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            userImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            userImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            userImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            userImageView.widthAnchor.constraint(lessThanOrEqualToConstant: maxSize),
            userImageView.heightAnchor.constraint(lessThanOrEqualToConstant: maxSize)
            ])
    }
}
