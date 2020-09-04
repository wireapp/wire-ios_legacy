//
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
import avs
import WireSyncEngine

protocol AVSIdentifierProvider {
    var stream: Stream { get }
}

extension AVSVideoView: AVSIdentifierProvider {
    
    var stream: Stream {
        return Stream(
            streamId: AVSClient(userId: UUID(uuidString: userid)!, clientId: clientid),
            participantName: nil,
            microphoneState: .unmuted,
            videoState: .none)
    }
}

class BaseVideoPreviewView: UIView, OrientableViewProtocol, AVSIdentifierProvider {
    var stream: Stream {
        didSet {
            updateUserDetails()
            updateFillMode()
        }
    }
    
    private var detailsConstraints: UserDetailsConstraints?
    private var isCovered: Bool
    
    private var userDetailsAlpha: CGFloat {
        return isCovered ? 0 : 1
    }
    
    let userDetailsView = VideoParticipantDetailsView()
    
    init(stream: Stream, isCovered: Bool) {
        self.stream = stream
        self.isCovered = isCovered
        
        super.init(frame: .zero)

        setupViews()
        createConstraints()
        updateUserDetails()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserDetailsVisibility), name: .videoGridVisibilityChanged, object: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    func updateUserDetails() {
        userDetailsView.name = stream.participantName
        userDetailsView.microphoneIconStyle = MicrophoneIconStyle(state: stream.microphoneState)
        userDetailsView.alpha = userDetailsAlpha
    }
    
    func updateFillMode() {
        // no-op
    }
    
    func setupViews() {
        backgroundColor = .graphite
        userDetailsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userDetailsView)
        userDetailsView.alpha = 0.0
    }
    
    func createConstraints() {
        detailsConstraints = UserDetailsConstraints(view: userDetailsView, superview: self, safeAreaInsets: safeAreaInsetsOrFallback)
       
        NSLayoutConstraint.activate([userDetailsView.heightAnchor.constraint(equalToConstant: 24)])
    }
    
    // MARK: - Orientation
    func layoutForOrientation() {
        guard let superview = superview else { return }
        
        let delta = OrientationDelta()
        
        transform = CGAffineTransform(rotationAngle: -delta.radianValue)
        frame = superview.bounds
    
        detailsConstraints?.adjustEdges(to: delta, safeAreaInsets: safeAreaInsetsOrFallback)
        
        layoutSubviews()
    }
    
    
    /// Represents the orientation differential between the interface orientation (as a reference) and the device orientation
    enum OrientationDelta {
        case shiftedRight
        case shiftedLeft
        case upsideDown
        case equal
        case unknown
        
        static var rightAngleValue: CGFloat { return AngleType.right.radianValue }
        static var leftAngleValue: CGFloat { return -AngleType.right.radianValue }
        static var upsideDownAngleValue: CGFloat { return AngleType.straight.radianValue }
        static var normalValue: CGFloat { return AngleType.full.radianValue }
        
        init(interfaceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation,
             deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation) {
            let angle = deviceOrientation.angle - interfaceOrientation.angle
            self.init(angle: angle)
        }
        
        init(angle: CGFloat) {
            switch angle {
            case OrientationDelta.upsideDownAngleValue:
                self = .upsideDown
            case OrientationDelta.leftAngleValue:
                self = .shiftedLeft
            case OrientationDelta.rightAngleValue:
                self = .shiftedRight
            case OrientationDelta.normalValue:
                self = .equal
            default:
                self = .unknown
            }
        }
        
        var radianValue: CGFloat {
            switch self {
            case .upsideDown:
                return OrientationDelta.upsideDownAngleValue
            case .shiftedLeft:
                return OrientationDelta.leftAngleValue
            case .shiftedRight:
                return OrientationDelta.rightAngleValue
            default:
                return OrientationDelta.normalValue
            }
        }
        
        var edgeInsetsShiftAmount: Int {
            switch self {
            case .shiftedLeft:
                return 1
            case .shiftedRight:
                return -1
            case .upsideDown:
                return 2
            default:
                return 0
            }
        }
    }
        
    // MARK: - Visibility
    @objc private func updateUserDetailsVisibility(_ notification: Notification?) {
        guard let isCovered = notification?.userInfo?[VideoGridViewController.isCoveredKey] as? Bool else {
            return
        }
        self.isCovered = isCovered
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.userDetailsView.alpha = self.userDetailsAlpha
        })
    }
}

// MARK: - User Details Constraints
private struct UserDetailsConstraints {
    private var bottom: NSLayoutConstraint
    private var leading: NSLayoutConstraint
    private var trailing: NSLayoutConstraint
    
    private let margin: CGFloat = 8
    
    init(view: UIView, superview: UIView, safeAreaInsets insets: UIEdgeInsets) {
        bottom = view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        leading = view.leadingAnchor.constraint(equalTo: superview.leadingAnchor)
        trailing = view.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor)
        adjustEdges(to: BaseVideoPreviewView.OrientationDelta(), safeAreaInsets: insets)
        NSLayoutConstraint.activate([bottom, leading, trailing])
    }
    
    func adjustEdges(to orientation: BaseVideoPreviewView.OrientationDelta, safeAreaInsets insets: UIEdgeInsets) {
        let orientedInsets = insets.adjusted(to: orientation)
        
        leading.constant = margin + orientedInsets.left
        trailing.constant = -(margin + orientedInsets.right)
        bottom.constant = -(margin + orientedInsets.bottom)
    }
}

// MARK: - Helpers

enum AngleType {
    case right
    case straight
    case full
    
    var radianValue: CGFloat {
        switch self {
        case .right:
            return .pi / 2
        case .straight:
            return .pi
        case .full:
            return 0
        }
    }
}

private extension UIDeviceOrientation {
    var angle: CGFloat {
        switch self {
        case .landscapeLeft:
            return -(.pi / 2)
        case .landscapeRight:
            return .pi / 2
        case .portraitUpsideDown:
            return .pi
        default:
            return 0
        }
    }
}

private extension UIInterfaceOrientation {
    var angle: CGFloat {
        switch self {
        case .landscapeLeft:
            return .pi / 2
        case .landscapeRight:
            return -(.pi / 2)
        case .portraitUpsideDown:
            return .pi
        default:
            return 0
        }
    }
}
