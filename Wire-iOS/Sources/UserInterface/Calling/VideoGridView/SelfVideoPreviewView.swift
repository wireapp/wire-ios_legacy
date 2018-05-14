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

protocol AVSIdentifierProvider {
    var identifier: String { get }
}

extension AVSVideoView: AVSIdentifierProvider {
    var identifier: String {
        return userid
    }
}

final class SelfVideoPreviewView: UIView, AVSIdentifierProvider {

    private let previewView = AVSVideoPreview()
    private let mutedOverlayView = UIView()
    private let mutedIconImageView = UIImageView()
    let identifier: String
    
    var isMuted = false {
        didSet {
            mutedOverlayView.isHidden = !isMuted
            mutedIconImageView.isHidden = !isMuted
        }
    }
    
    init(identifier: String) {
        self.identifier = identifier
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        mutedOverlayView.isHidden = true
        mutedIconImageView.isHidden = true
        mutedIconImageView.contentMode = .center
        mutedOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let iconColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: .dark)
        mutedIconImageView.image = UIImage(for: .microphoneWithStrikethrough, iconSize: .tiny, color: iconColor)
        [previewView, mutedOverlayView, mutedIconImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }
    
    private func createConstraints() {
        previewView.fitInSuperview()
        mutedOverlayView.fitInSuperview()
        mutedIconImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        mutedIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

}
