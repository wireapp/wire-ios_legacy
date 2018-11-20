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


import Foundation
@testable import Wire

extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    @objc public func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: self.bounds, style: .plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.layoutMargins = self.layoutMargins
        
        let size = self.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0.0) , withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.layoutSubviews()
        
        self.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        self.contentView.bounds = self.bounds
        
        tableView.reloadData()
        tableView.bounds = self.bounds
        tableView.layoutIfNeeded()
        
        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: size.height)
            ])
        
        self.layoutSubviews()
        return tableView
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.size.height
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self
    }
}


extension StaticString {
    func utf8SignedStart() -> UnsafePointer<Int8> {
        let fileUnsafePointer = self.utf8Start
        let reboundToSigned = fileUnsafePointer.withMemoryRebound(to: Int8.self, capacity: self.utf8CodeUnitCount) {
            return UnsafePointer($0)
        }
        return reboundToSigned
    }
}

// MARK: - verify the snapshots in multiple devices
extension ZMSnapshotTestCase {
    static let phoneScreenSizes: [String:CGSize] = [
        "iPhone-4_0_Inch": ZMDeviceSizeIPhone5,
        "iPhone-4_7_Inch": ZMDeviceSizeIPhone6,
        "iPhone-5_5_Inch": ZMDeviceSizeIPhone6Plus,
        "iPhone-5_8_Inch": ZMDeviceSizeIPhoneX,
        "iPhone-6_5_Inch": ZMDeviceSizeIPhoneXR
    ]

    /// we should add iPad Pro sizes
    static let tabletScreenSizes: [String:CGSize] = [
        "iPad-Portrait":  ZMDeviceSizeIPadPortrait,
        "iPad-Landscape": ZMDeviceSizeIPadLandscape
    ]

    
    typealias ConfigurationWithDeviceType = (_ view: UIView, _ isPad: Bool) -> Void
    typealias Configuration = (_ view: UIView) -> Void

    private static var deviceScreenSizes: [String:CGSize] = {
        return phoneScreenSizes.merging(tabletScreenSizes) { $1 }
    }()

    func verifyMultipleSize(view: UIView, extraLayoutPass: Bool, inSizes sizes: [String:CGSize], configuration: ConfigurationWithDeviceType?,
                            file: StaticString = #file, line: UInt = #line) {
        for (deviceName, size) in sizes {
            view.frame = CGRect(origin: .zero, size: size)
            if let configuration = configuration {
                let iPad = size.equalTo(ZMDeviceSizeIPadLandscape) || size.equalTo(ZMDeviceSizeIPadPortrait)
                UIView.performWithoutAnimation({
                    configuration(view, iPad)
                })
            }
            verify(view: view,
                   extraLayoutPass: extraLayoutPass,
                   deviceName: deviceName,
                   file: file,
                   line: line)
        }
    }
    

    func verifyInAllPhoneSizes( view: UIView,
                                extraLayoutPass: Bool,
                                file: StaticString = #file,
                                line: UInt = #line,
                                configurationBlock configuration: Configuration?) {
        verifyMultipleSize(view: view, extraLayoutPass: extraLayoutPass, inSizes: ZMSnapshotTestCase.phoneScreenSizes, configuration: { view, isPad in
            if let configuration = configuration {
                configuration(view)
            }
        }, file: file, line: line)
    }

    func verifyInAllDeviceSizes(view: UIView, extraLayoutPass: Bool, file: StaticString = #file, line: UInt = #line, configurationBlock configuration: ConfigurationWithDeviceType? = nil) {

        verifyMultipleSize(view: view, extraLayoutPass: extraLayoutPass, inSizes: ZMSnapshotTestCase.deviceScreenSizes,
                           configuration: configuration,
                           file: file, line: line)
    }
}

// MARK: - Helpers
extension ZMSnapshotTestCase {
    func containerView(with view: UIView) -> UIView {
        let container = UIView(frame: view.bounds)
        container.backgroundColor = snapshotBackgroundColor
        container.addSubview(view)

        view.fitInSuperview()
        view.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    func tabletSizes() -> [NSValue] {
        return [NSValue(cgSize: ZMDeviceSizeIPadPortrait), NSValue(cgSize: ZMDeviceSizeIPadLandscape)]
    }

    func phoneWidths() -> Set<CGFloat> {
        return Set(phoneSizes().map( { boxedSize in
            return boxedSize.cgSizeValue.width
        }))
    }

    func phoneSizes() -> [NSValue] {
        return [NSValue(cgSize: ZMDeviceSizeIPhone5),
                NSValue(cgSize: ZMDeviceSizeIPhone6),
                NSValue(cgSize: ZMDeviceSizeIPhone6Plus),
                NSValue(cgSize: ZMDeviceSizeIPhoneX),     ///same size as iPhone Xs Max
            NSValue(cgSize: ZMDeviceSizeIPhoneXR)]
    }

    func snapshotVerify(view: UIView,
                        identifier: String? = nil,
                        suffix: NSOrderedSet? = FBSnapshotTestCaseDefaultSuffixes(),
                        tolerance: CGFloat = 0,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let errorDescription = snapshotVerifyViewOrLayer(view,
                                                         identifier: identifier,
                                                         suffixes: suffix,
                                                         tolerance: tolerance, defaultReferenceDirectory: (FB_REFERENCE_IMAGE_DIR))

        let noErrors: Bool = errorDescription == nil
        XCTAssert(noErrors, "\(String(describing: errorDescription))", file:file, line:line)
    }

//    func snapshotVerify(view: UIView,
//                        finalIdentifier: String? = nil,
//                        file: StaticString = #file,
//                        line: UInt = #line
//        ) {
//        snapshotVerify(view: view, identifier: finalIdentifier, suffix: FBSnapshotTestCaseDefaultSuffixes(), tolerance: 0)
//    }
}

extension ZMSnapshotTestCase {

    /// Performs an assertion with the given view and the recorded snapshot.
    func verify(view: UIView,
                extraLayoutPass: Bool = false,
                tolerance: CGFloat = 0,
                identifier: String? = nil,
                deviceName: String? = nil,
                file: StaticString = #file,
                line: UInt = #line
        ) {
        let container = containerView(with: view)
        if assertEmptyFrame(container, file: file.utf8SignedStart(), line: line) {
            return
        }

        var finalIdentifier: String?

        if 0 == (identifier?.count ?? 0) {
            if let deviceName = deviceName,
                deviceName.count > 0 {
                finalIdentifier = deviceName
            }
        } else {
            if let deviceName = deviceName,
                deviceName.count > 0 {
                finalIdentifier = "\(identifier ?? "")-\(deviceName)"
            } else {
                finalIdentifier = "\(identifier ?? "")"
            }
        }

        if extraLayoutPass {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        snapshotVerify(view: container,
                       identifier: finalIdentifier,
                       suffix: FBSnapshotTestCaseDefaultSuffixes(),
                       tolerance: tolerance,
                       file: file,
                       line: line)

        assertAmbigousLayout(container, file: file.utf8SignedStart(), line: line)
    }

    func verifyView(view: UIView, extraLayoutPass: Bool, width: CGFloat,
                    file: StaticString = #file,
                    line: UInt = #line
        ) {
        let container = containerView(with: view)

        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: width)
            ])

        container.setNeedsLayout()
        container.layoutIfNeeded()
        container.setNeedsLayout()
        container.layoutIfNeeded()
        if assertEmptyFrame(container, file: file.utf8SignedStart(), line: line) {
            return
        }

        if extraLayoutPass {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        snapshotVerify(view: container, identifier:"\(Int(width))", file: file, line: line)
    }

    /// Performs multiple assertions with the given view using the screen sizes of
    /// the common iPhones in Portrait and iPad in Landscape and Portrait.
    /// This method only makes sense for views that will be on presented fullscreen.
    func verifyInAllPhoneWidths(view: UIView, file: StaticString = #file, line: UInt = #line) {
        assertAmbigousLayout(view, file: file.utf8SignedStart(), line: line)
        for width: CGFloat in phoneWidths() {
            verifyView(view: view, extraLayoutPass: false, width: width, file: file, line: line)
        }
    }

    func verifyInAllTabletWidths(view: UIView,
                                 extraLayoutPass: Bool = false,
                                 file: StaticString = #file, line: UInt = #line) {
        assertAmbigousLayout(view, file: file.utf8SignedStart(), line: line)
        for value: NSValue in tabletSizes() {
            verifyView(view: view, extraLayoutPass: extraLayoutPass, width: value.cgSizeValue.width, file: file, line: line)
        }
    }

    func verifyInAllDeviceSizes(view: UIView, file: StaticString = #file, line: UInt = #line, configuration: @escaping (UIView, Bool) -> () = { _, _ in }) {
        verifyInAllDeviceSizes(view: view, extraLayoutPass: false, file: file, line: line, configurationBlock: configuration)
    }


    /// return the smallest iPhone screen size that Wire app supports
    private var defaultIPhoneSize: CGSize {
        return ZMDeviceSizeIPhone5
    }

    func verifyInIPhoneSize(view: UIView, file: StaticString = #file, line: UInt = #line) {

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: defaultIPhoneSize.height),
            view.widthAnchor.constraint(equalToConstant: defaultIPhoneSize.width)
            ])

        view.setNeedsLayout()
        view.layoutIfNeeded()
        verify(view: view, file: file, line: line)
    }
    
    func verifyInAllIPhoneSizes(view: UIView, extraLayoutPass: Bool = false, file: StaticString = #file, line: UInt = #line, configurationBlock: ((UIView) -> Swift.Void)? = nil) {
        verifyInAllPhoneSizes(view: view, extraLayoutPass: extraLayoutPass, file: file, line: line, configurationBlock: configurationBlock)
    }
    
    func verifyInAllColorSchemes(view: UIView,
                                 tolerance: CGFloat = 0,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        if var themeable = view as? Themeable {
            themeable.colorSchemeVariant = .light
            snapshotBackgroundColor = .white
            verify(view: view, tolerance: tolerance, identifier: "LightTheme", file: file, line: line)
            themeable.colorSchemeVariant = .dark
            snapshotBackgroundColor = .black
            verify(view: view, tolerance: tolerance, identifier: "DarkTheme", file: file, line: line)
        } else {
            XCTFail("View doesn't support Themable protocol")
        }
    }
    
    @available(iOS 11.0, *)
    func verifySafeAreas(
        viewController: UIViewController,
        tolerance: Float = 0,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        viewController.viewSafeAreaInsetsDidChange()
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        verify(view: viewController.view)
    }
    
    func resetColorScheme() {
        ColorScheme.default.variant = .light

        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }
}

// MARK: - UIAlertController
extension ZMSnapshotTestCase {
    func verifyAlertController(_ controller: UIAlertController, file: StaticString = #file, line: UInt = #line) {
        // Given
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 667))
        let container = UIViewController()
        container.loadViewIfNeeded()
        window.rootViewController = container
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        // When
        let presentationExpectation = expectation(description: "It should be presented")
        container.present(controller, animated: false) {
            presentationExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2, handler: nil)
        verify(view: controller.view, file: file, line: line)
    }
}
