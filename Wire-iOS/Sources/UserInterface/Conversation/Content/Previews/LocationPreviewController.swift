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
import WireDataModel

/// Displays the preview of a location message.
final class LocationPreviewController: TintColorCorrectedViewController {

    let message: ZMConversationMessage
    private var actionController: ConversationMessageActionController!

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
        super.init(nibName: nil, bundle: nil)
        actionController = ConversationMessageActionController(responder: actionResponder, message: message, context: .content, view: view)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .from(scheme: .placeholderBackground)

        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
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
        [view, containerView, mapView, containerView, addressContainerView, addressLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            mapView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: containerView.rightAnchor),

            addressContainerView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            addressContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            addressContainerView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            addressContainerView.topAnchor.constraint(equalTo: addressLabel.topAnchor, constant: -12),
            addressLabel.bottomAnchor.constraint(equalTo: addressContainerView.bottomAnchor, constant: -12),
            addressLabel.leftAnchor.constraint(equalTo: addressContainerView.leftAnchor, constant: 12),
            addressLabel.rightAnchor.constraint(equalTo: addressContainerView.rightAnchor, constant: -12)
        ])
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

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    override var previewActionItems: [UIPreviewActionItem] {
        return actionController.previewActionItems
    }

}
