//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

enum FontBook {

    enum FontStyle {

        case title3
        case headline
        case body
        case subheadline
        case caption1
        case title3Bold
        case calloutBold
        case footnote

    }

    static func font(for style: FontStyle) -> UIFont {
        switch style {
        case .title3:
            return .preferredFont(forTextStyle: .title3)

        case .headline:
            return .preferredFont(forTextStyle: .headline)

        case .body:
            return .preferredFont(forTextStyle: .body)

        case .subheadline:
            return .preferredFont(forTextStyle: .subheadline)

        case .caption1:
            return .preferredFont(forTextStyle: .caption1)

        case .title3Bold:
            return .preferredFont(forTextStyle:
                    .title3)

        case .calloutBold:
            return .preferredFont(forTextStyle: .callout)

        case .footnote:
            return .preferredFont(forTextStyle: .footnote)
        }
    }

    static var label: UILabel {
        let label = UILabel()
        label.font = .font(for: .title3)
        return label
    }

}

extension UIFont {

    enum FontStyle {
            case title3
            case headline
            case body
            case subheadline
            case caption1
            case title3Bold
            case calloutBold
            case footnote

    }

    static func font(for style: FontStyle) -> UIFont {
            switch style {
            case .title3:
                return .preferredFont(forTextStyle: .title3)

            case .headline:
                return .preferredFont(forTextStyle: .headline)

            case .body:
                return .preferredFont(forTextStyle: .body)

            case .subheadline:
                return .preferredFont(forTextStyle: .subheadline)

            case .caption1:
                return .preferredFont(forTextStyle: .caption1)

            case .title3Bold:
                return .preferredFont(forTextStyle:
                        .title3)

            case .calloutBold:
                return .preferredFont(forTextStyle: .callout)

            case .footnote:
                return .preferredFont(forTextStyle: .footnote)
            }
        }

}

class MyLabel: UILabel {

    var fontStyle: UIFont.FontStyle {
        didSet {
            font = .font(for: fontStyle)
        }
    }

    init(
        text: String = "",
        style: UIFont.FontStyle = .body
    ) {
        fontStyle = style
        super.init(frame: .zero)
        self.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
