//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireDataModel

final class FileMessageRestrictionView: BaseMessageRestrictionView {

    // MARK: - Properties

    let fileBlockView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .from(scheme: .background)
        return imageView
    }()

    // MARK: - Life cycle

    init() {
        super.init(messageType: .file)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(for message: ZMConversationMessage?) {
        super.configure()

        guard let filename = message?.filename else { return }
        let fileNameAttributed = filename.uppercased() && .smallSemiboldFont && .from(scheme: .textForeground)

        topLabel.attributedText = fileNameAttributed
    }

    // MARK: - Helpers

    override func setupViews() {
        super.setupViews()

        [topLabel, bottomLabel, iconView, fileBlockView].forEach(self.addSubview)
    }

    override func setupIconView() {
        super.setupIconView()

        fileBlockView.setTemplateIcon(.block, size: 8)
    }

    override func createConstraints() {
        super.createConstraints()
        fileBlockView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // top label
            topLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            topLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            topLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),

            // bottom label
            bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 2),
            bottomLabel.leadingAnchor.constraint(equalTo: topLabel.leadingAnchor),
            bottomLabel.trailingAnchor.constraint(equalTo: topLabel.trailingAnchor),

            // icon view
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            // fileBlock view
            fileBlockView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            fileBlockView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 3)
        ])
    }
}

extension ZMConversationMessage {
    var filename: String? {
        guard let fileMessageData = self.fileMessageData,
              let filepath = fileMessageData.filename as NSString? else {
            return nil
        }
        return (filepath.lastPathComponent as NSString).deletingPathExtension
    }
}
