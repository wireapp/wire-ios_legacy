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

import UIKit
import MapKit
import Cartography

/// Displays the preview of a location message.
class LocationPreviewController: TintColorCorrectedViewController {

    let message: ZMConversationMessage
    weak var messageActionDelegate: MessageActionResponder?

    private let mapView = MKMapView()
    private let containerView = UIView()
    private let addressContainerView = UIView()
    private let addressLabel = UILabel()

    let labelFont = UIFont.normalFont
    let labelTextColor = UIColor.textForeground
    let containerColor = UIColor.placeholderBackground

    // MARK: - Initialization

    init(message: ZMConversationMessage) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.cas_styleClass = "container-view"
        configureViews()
        createConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private func configureViews() {
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.mapType = .standard
        mapView.showsPointsOfInterest = true
        mapView.showsBuildings = true
        mapView.isUserInteractionEnabled = false

        view.addSubview(containerView)
        [mapView, addressContainerView].forEach(containerView.addSubview)
        addressContainerView.addSubview(addressLabel)

        guard let locationData = message.locationMessageData else { return }

        if let address = locationData.name {
            addressContainerView.isHidden = false
            addressLabel.text = address
            addressLabel.numberOfLines = 0
        } else {
            addressContainerView.isHidden = true
        }

        updateMapLocation(withLocationData: locationData)

        let annotation = MKPointAnnotation()
        annotation.coordinate = locationData.coordinate
        mapView.addAnnotation(annotation)

        addressLabel.font = labelFont
        addressLabel.textColor = labelTextColor
        addressContainerView.backgroundColor = containerColor
    }

    private func createConstraints() {
        constrain(view, containerView, mapView) { contentView, container, mapView in
            container.edges == contentView.edges
            mapView.edges == container.edges
        }

        constrain(containerView, addressContainerView, addressLabel) { container, addressContainer, addressLabel in
            addressContainer.left == container.left
            addressContainer.bottom == container.bottom
            addressContainer.right == container.right
            addressContainer.top == addressLabel.top - 12
            addressLabel.bottom == addressContainer.bottom - 12
            addressLabel.left == addressContainer.left + 12
            addressLabel.right == addressContainer.right - 12
        }
    }

    // MARK: - Map

    func updateMapLocation(withLocationData locationData: ZMLocationMessageData) {
        let region: MKCoordinateRegion

        if locationData.zoomLevel != 0 {
            let span = MKCoordinateSpan(zoomLevel: Int(locationData.zoomLevel), viewSize: Float(view.frame.size.height))
            region = MKCoordinateRegion(center: locationData.coordinate, span: span)
        } else {
            region = MKCoordinateRegionMakeWithDistance(locationData.coordinate, 250, 250)
        }

        mapView.setRegion(region, animated: false)
    }

    // MARK: - Preview

    override var previewActionItems: [UIPreviewActionItem] {

        var actions: [UIPreviewActionItem] = []

        // Copy

        let copyAction = UIPreviewAction(title: "content.message.copy".localized, style: .default) { [weak self] _, _ in
            guard let `self` = self else {
                return
            }
            self.copyLocation()
        }

        actions.append(copyAction)

        // Like / unlike

        if message.liked || message.canBeLiked {
            let likeActionKey = message.liked ? "unlike" : "like"
            let toggleLikeAction = UIPreviewAction(title: "content.message.\(likeActionKey)".localized, style: .default) { [weak self] _, _ in
                guard let `self` = self else {
                    return
                }
                self.toggleLike()
            }

            actions.append(toggleLikeAction)
        }

        // Share

        let shareAction = UIPreviewAction(title: "content.message.forward".localized, style: .default) { [weak self] _, _ in
            guard let `self` = self else {
                return
            }
            self.forwardMessage()
        }

        actions.append(shareAction)

        // Delete

        if message.canBeDeleted {
            let deleteAction = UIPreviewAction(title: "content.message.delete_ellipsis".localized, style: .default) { [weak self] _, _ in
                guard let `self` = self else {
                    return
                }
                self.deleteMessage()
            }

            actions.append(deleteAction)
        }

        return actions
    }

    /// Copies the coordinates into the clipboard.
    private func copyLocation() {
        guard let locationMessageData = message.locationMessageData else { return }
        let coordinates = "\(locationMessageData.latitude), \(locationMessageData.longitude)"
        UIPasteboard.general.string = message.locationMessageData?.name ?? coordinates
    }

    /// Invert the like status of the message.
    private func toggleLike() {
        ZMUserSession.shared()?.enqueueChanges {
            self.message.liked = !self.message.liked
        }
    }

    /// Forwards the message.
    private func forwardMessage() {
        messageActionDelegate?.wants(toPerform: .forward, for: message)
    }

    /// Deletes the current message.
    private func deleteMessage() {
        messageActionDelegate?.wants(toPerform: .delete, for: message)
    }

}
