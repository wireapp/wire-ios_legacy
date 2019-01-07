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
    let actionController: ConversationMessageActionController

    private var mapView = MKMapView()
    private let containerView = UIView()
    private let addressContainerView = UIView()
    private let addressLabel = UILabel()

    let labelFont = UIFont.normalFont
    let labelTextColor = UIColor.from(scheme: .textForeground)
    let containerColor = UIColor.from(scheme: .placeholderBackground)

    // MARK: - Initialization

    init(message: ZMConversationMessage, actionResponder: MessageActionResponder) {
        self.message = message
        self.actionController = ConversationMessageActionController(responder: actionResponder, message: message, context: .content)
        super.init(nibName: nil, bundle: nil)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .from(scheme: .placeholderBackground)

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

    func updateMapLocation(withLocationData locationData: LocationMessageData) {
        let region: MKCoordinateRegion

        if locationData.zoomLevel != 0 {
            let span = MKCoordinateSpan(zoomLevel: Int(locationData.zoomLevel), viewSize: Float(view.frame.size.height))
            region = MKCoordinateRegion(center: locationData.coordinate, span: span)
        } else {
            region = MKCoordinateRegion(center: locationData.coordinate, latitudinalMeters: 250, longitudinalMeters: 250)
        }

        mapView.setRegion(region, animated: false)
    }

    // MARK: - Preview

    override var previewActionItems: [UIPreviewActionItem] {
        return actionController.makePreviewActions()
    }

}
