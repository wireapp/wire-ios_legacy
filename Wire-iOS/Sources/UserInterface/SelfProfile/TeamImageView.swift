
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
import Cartography

final class TeamImageView: UIImageView {

    public enum TeamImageViewStyle {
        case small
        case big
    }

    public enum Content {
        case teamImage(Data)
        case teamName(String)

        init?(imageData: Data?, name: String?) {
            if let imageData = imageData {
                self = .teamImage(imageData)
            } else if let name = name, !name.isEmpty {
                self = .teamName(name)
            } else {
                return nil
            }
        }
    }

    var content: Content {
        didSet {
            updateImage()
        }
    }

    private var lastLayoutBounds: CGRect = .zero
    internal let initialLabel = UILabel()
    public var style: TeamImageViewStyle = .small {
        didSet {
            applyStyle(style: style)
        }
    }

    func applyStyle(style: TeamImageViewStyle ) {
        switch style {
        case .small:
            initialLabel.font = .smallSemiboldFont
        case .big:
            initialLabel.font = .largeThinFont
        case .team:
            initialLabel.font = .largeThinFont
        }

        initialLabel.textColor = .from(scheme: .textForeground, variant: .light)
        backgroundColor = .from(scheme: .background, variant: .light)
    }

    private func updateRoundCorner() {
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    init(content: Content, style: TeamImageViewStyle = .small) {
        self.content = content
        super.init(frame: .zero)

        initialLabel.textAlignment = .center
        self.addSubview(self.initialLabel)
        self.accessibilityElements = [initialLabel]

        constrain(self, initialLabel) { selfView, initialLabel in
            initialLabel.centerY == selfView.centerY
            initialLabel.centerX == selfView.centerX
        }

        self.updateImage()

        updateRoundCorner()

        self.style = style

        applyStyle(style: style)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if !bounds.equalTo(lastLayoutBounds) {
            lastLayoutBounds = self.bounds
            updateRoundCorner()
        }
    }

    private func updateImage() {
        switch content {
        case .teamImage(let data):
            image = UIImage(data: data)
            initialLabel.text = ""
        case .teamName(let name):
            image = nil
            initialLabel.text = name.first.map(String.init)
        }
    }
}
