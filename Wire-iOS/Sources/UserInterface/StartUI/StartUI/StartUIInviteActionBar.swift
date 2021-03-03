//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class StartUIInviteActionBar: UIView {

    var backgroundView: UIVisualEffectView?
    var bottomEdgeConstraint: NSLayoutConstraint!

    private(set) var inviteButton: Button!

    private let padding: CGFloat = 12

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)

        createInviteButton()
        createConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardFrameWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createInviteButton() {
        inviteButton = Button(style: ButtonStyle.empty, variant: .dark)
        inviteButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 3, right: 8)
        addSubview(inviteButton)
        inviteButton.setTitle("peoplepicker.invite_more_people".localized, for: .normal)
    }

    override var isHidden: Bool {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: isHidden ? 0 : 56.0)
    }

    private func createConstraints() {
        inviteButton.translatesAutoresizingMaskIntoConstraints = false

        bottomEdgeConstraint = inviteButton.fitInSuperview(with: EdgeInsets(top: padding, leading: padding * 2, bottom: padding + UIScreen.safeArea.bottom, trailing: padding * 2))[.bottom]
        inviteButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
    }

    // MARK: - UIKeyboard notifications

    @objc
    private func keyboardFrameWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let beginOrigin = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.origin.y,
              let endOrigin = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.origin.y
        else { return }

        let diff: CGFloat = beginOrigin - endOrigin

        UIView.animate(withKeyboardNotification: notification, in: self, animations: { [weak self] _ in
            guard let weakSelf = self else { return }

            weakSelf.bottomEdgeConstraint.constant = -weakSelf.padding - (diff > 0 ? 0 : UIScreen.safeArea.bottom)
            weakSelf.layoutIfNeeded()
        })
    }

}
