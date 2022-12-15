//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import WireDataModel
import MapKit
import CoreLocation
import UIKit

protocol LocationSelectionViewControllerDelegate: AnyObject {
    func locationSelectionViewController(_ viewController: LocationSelectionViewController, didSelectLocationWithData locationData: LocationData)
    func locationSelectionViewControllerDidCancel(_ viewController: LocationSelectionViewController)
}

final class LocationSelectionViewController: UIViewController {

    weak var delegate: LocationSelectionViewControllerDelegate?
    let locationButton: IconButton = {
        let button = IconButton()
        button.setIcon(.location, size: .tiny, for: [])
        button.borderWidth = 0.5
        button.setBorderColor(SemanticColors.View.borderInputBar, for: .normal)
        button.circular = true
        button.backgroundColor = SemanticColors.View.backgroundDefault
        button.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)

        return button
    }()

    let locationButtonContainer = UIView()
    fileprivate var mapView = MKMapView()
    fileprivate let toolBar = ModalTopBar()
    fileprivate let locationManager = CLLocationManager()
    fileprivate let geocoder = CLGeocoder()
    fileprivate let sendViewController = LocationSendViewController()
    fileprivate let pointAnnotation = MKPointAnnotation()
    private lazy var annotationView: MKPinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: String(describing: type(of: self)))
    fileprivate var userShowedInitially = false
    fileprivate var mapDidRender = false

    fileprivate var userLocationAuthorized: Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        mapView.delegate = self
        toolBar.delegate = self
        sendViewController.delegate = self

        configureViews()
        createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !userLocationAuthorized { mapView.restoreLocation(animated: true) }
        locationManager.requestWhenInUseAuthorization()
        updateUserLocation()

        endEditing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingHeading()
        mapView.storeLocation()
    }

    fileprivate func configureViews() {
        addChild(sendViewController)
        sendViewController.didMove(toParent: self)
        [mapView, sendViewController.view, toolBar, locationButton].forEach(view.addSubview)
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)

        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        toolBar.configure(title: title!, subtitle: nil, topAnchor: safeTopAnchor)
        pointAnnotation.coordinate = mapView.centerCoordinate

        mapView.addSubview(annotationView)
    }

    fileprivate func createConstraints() {
        guard let sendController = sendViewController.view else { return }

        [mapView, sendController, annotationView, toolBar, locationButton].prepareForLayout()

        NSLayoutConstraint.activate([
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.safeArea.top),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            sendController.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendController.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendController.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sendController.heightAnchor.constraint(equalToConstant: 56 + UIScreen.safeArea.bottom),
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.topAnchor.constraint(equalTo: view.topAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            annotationView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor, constant: 8.5),
            annotationView.bottomAnchor.constraint(equalTo: mapView.centerYAnchor, constant: 5),
            annotationView.heightAnchor.constraint(equalToConstant: 39),
            annotationView.widthAnchor.constraint(equalToConstant: 32),

            locationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            locationButton.bottomAnchor.constraint(equalTo: sendController.topAnchor, constant: -16),
            locationButton.widthAnchor.constraint(equalToConstant: 28),
            locationButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    @objc fileprivate func locationButtonTapped(_ sender: IconButton) {
        zoomToUserLocation(true)
    }

    fileprivate func updateUserLocation() {
        mapView.showsUserLocation = userLocationAuthorized
        if userLocationAuthorized {
            locationManager.startUpdatingLocation()
        }
    }

    fileprivate func zoomToUserLocation(_ animated: Bool) {
        guard userLocationAuthorized else { return presentUnauthorizedAlert() }
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 50, longitudinalMeters: 50)
        mapView.setRegion(region, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    fileprivate func presentUnauthorizedAlert() {
        let localize: (String) -> String = { ("location.unauthorized_alert." + $0).localized }
        let alertController = UIAlertController(title: localize("title"), message: localize("message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: localize("cancel"), style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: localize("settings"), style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }

        [cancelAction, settingsAction].forEach(alertController.addAction)
        present(alertController, animated: true, completion: nil)
    }

    fileprivate func formatAndUpdateAddress() {
        guard mapDidRender else { return }
        geocoder.reverseGeocodeLocation(mapView.centerCoordinate.location) { [weak self] placemarks, error in
            guard nil == error, let placemark = placemarks?.first else { return }
            if let address = placemark.formattedAddress(false), !address.isEmpty {
                self?.sendViewController.address = address
            } else {
                self?.sendViewController.address = nil
            }
        }
    }
}

extension LocationSelectionViewController: LocationSendViewControllerDelegate {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController) {
        let locationData = mapView.locationData(name: viewController.address)
        delegate?.locationSelectionViewController(self, didSelectLocationWithData: locationData)
        dismiss(animated: true, completion: nil)
    }
}

extension LocationSelectionViewController: ModalTopBarDelegate {

    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        delegate?.locationSelectionViewControllerDidCancel(self)
    }

}

extension LocationSelectionViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateUserLocation()
    }

}

extension LocationSelectionViewController: MKMapViewDelegate {

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        mapDidRender = true
        formatAndUpdateAddress()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        formatAndUpdateAddress()
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !userShowedInitially {
            userShowedInitially = true
            zoomToUserLocation(true)
        }
    }

}
