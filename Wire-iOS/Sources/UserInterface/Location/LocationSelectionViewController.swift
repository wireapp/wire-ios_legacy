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


import ZMCDataModel
import Cartography
import MapKit
import CoreLocation

@objc protocol LocationSelectionViewControllerDelegate: class {
    func locationSelectionViewController(viewController: LocationSelectionViewController, didSelectLocationWithData locationData: LocationData)
    func locationSelectionViewControllerDidCancel(viewController: LocationSelectionViewController)
}

@objc final public class LocationSelectionViewController: UIViewController {
    
    weak var delegate: LocationSelectionViewControllerDelegate?
    public let locationButton = IconButton()
    public let locationButtonContainer = UIView()
    private let mapView = MKMapView()
    private let toolBar: ModalTopBar
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let sendViewController = LocationSendViewController()
    private let pointAnnotation = MKPointAnnotation()
    private var annotationView: MKPinAnnotationView! = nil
    private var userShowedInitially = false
    private var mapDidRender = false

    private var userLocationAuthorized: Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .AuthorizedAlways || status == .AuthorizedWhenInUse
    }
    
    public init(forPopoverPresentation popover: Bool) {
        toolBar = ModalTopBar(forUseWithStatusBar: !popover)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented, user 'init(forPopoverPresentation:)'")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
        toolBar.delegate = self
        sendViewController.delegate = self
        configureViews()
        createConstraints()
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !userLocationAuthorized { mapView.restoreLocation(animated: true) }
        locationManager.requestWhenInUseAuthorization()
        updateUserLocation()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingHeading()
        mapView.storeLocation()
    }
    
    private func configureViews() {
        addChildViewController(sendViewController)
        sendViewController.didMoveToParentViewController(self)
        [mapView, sendViewController.view, toolBar, locationButton].forEach(view.addSubview)
        locationButton.addTarget(self, action: #selector(locationButtonTapped), forControlEvents: .TouchUpInside)
        locationButton.setIcon(.Location, withSize: .Tiny, forState: .Normal)
        locationButton.cas_styleClass = "back-button"
        mapView.rotateEnabled = false
        mapView.pitchEnabled = false
        toolBar.title = title
        pointAnnotation.coordinate = mapView.centerCoordinate
        annotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: String(self.dynamicType))
        mapView.addSubview(annotationView)
    }

    private func createConstraints() {
        constrain(view, mapView, sendViewController.view, annotationView, toolBar) { view, mapView, sendController, pin, toolBar in
            mapView.edges == view.edges
            sendController.leading == view.leading
            sendController.trailing == view.trailing
            sendController.bottom == view.bottom
            sendController.height == 56
            toolBar.leading == view.leading
            toolBar.top == view.top
            toolBar.trailing == view.trailing
            pin.centerX == mapView.centerX + 8.5
            pin.bottom == mapView.centerY + 5
            pin.height == 39
            pin.width == 32
        }
        
        constrain(view, sendViewController.view, locationButton) { view, sendController, button in
            button.leading == view.leading + 16
            button.bottom == sendController.top - 16
            button.width == 28
            button.height == 28
        }
    }
    
    @objc private func locationButtonTapped(sender: IconButton) {
        zoomToUserLocation(true)
    }
    
    private func updateUserLocation() {
        mapView.showsUserLocation = userLocationAuthorized
        if userLocationAuthorized {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func zoomToUserLocation(animated: Bool) {
        guard userLocationAuthorized else { return presentUnauthorizedAlert() }
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 50, 50)
        mapView.setRegion(region, animated: animated)
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIViewController.wr_supportedInterfaceOrientations()
    }
    
    private func presentUnauthorizedAlert() {
        let localize: String -> String = { ("location.unauthorized_alert." + $0).localized }
        let alertController = UIAlertController(title: localize("title"), message: localize("message"), preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: localize("cancel"), style: .Cancel , handler: nil)
        let settingsAction = UIAlertAction(title: localize("settings"), style: .Default) { _ in
            guard let url = NSURL(string: UIApplicationOpenSettingsURLString) else { return }
            UIApplication.sharedApplication().openURL(url)
        }
        
        [cancelAction, settingsAction].forEach(alertController.addAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func formatAndUpdateAddress() {
        guard mapDidRender else { return }
        geocoder.reverseGeocodeLocation(mapView.centerCoordinate.location) { [weak self] placemarks, error in
            guard nil == error, let placemark = placemarks?.first else { return }
            if let address = placemark.formattedAddress(false) where !address.isEmpty {
                self?.sendViewController.address = address
            } else {
                self?.sendViewController.address = nil
            }
        }
    }
}

extension LocationSelectionViewController: LocationSendViewControllerDelegate {
    public func locationSendViewControllerSendButtonTapped(viewController: LocationSendViewController) {
        let locationData = mapView.locationData(name: viewController.address)
        delegate?.locationSelectionViewController(self, didSelectLocationWithData: locationData)
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension LocationSelectionViewController: ModalTopBarDelegate {
    
    public func modelTopBarWantsToBeDismissed(topBar: ModalTopBar) {
        delegate?.locationSelectionViewControllerDidCancel(self)
    }
    
}

extension LocationSelectionViewController: CLLocationManagerDelegate {
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        updateUserLocation()
    }
    
}

extension LocationSelectionViewController: MKMapViewDelegate {
    
    public func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        mapDidRender = true
        formatAndUpdateAddress()
    }
    
    public func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        formatAndUpdateAddress()
    }
    
    public func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if !userShowedInitially {
            userShowedInitially = true
            zoomToUserLocation(true)
        }
    }

}
