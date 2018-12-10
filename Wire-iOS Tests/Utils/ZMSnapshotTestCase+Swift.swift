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
import Cartography
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
        
        constrain(tableView) { tableView in
            tableView.height == size.height
        }
        
        
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
                let iPad = size.equalTo(XCTestCase.ZMDeviceSizeIPadLandscape) || size.equalTo(XCTestCase.ZMDeviceSizeIPadPortrait)
                UIView.performWithoutAnimation({
                    configuration(view, iPad)
                })
            }
            verifyView(view, extraLayoutPass: extraLayoutPass, file: file.utf8SignedStart(), line: line, deviceName: deviceName)
        }
    }

    func verifyInAllPhoneSizes( view: UIView, extraLayoutPass: Bool, file: StaticString = #file, line: UInt = #line, configurationBlock configuration: Configuration?) {
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

// MARK: - verify view for a set of devices' widths

extension ZMSnapshotTestCase {
    /// Performs multiple assertions with the given view using the screen sizes of
    /// the common iPhones in Portrait and iPad in Landscape and Portrait.
    /// This method only makes sense for views that will be on presented fullscreen.
    func verifyInAllPhoneWidths(view: UIView,
                                extraLayoutPass: Bool = false,
                                tolerance: CGFloat = 0,
                                configuration: ((UIView) -> Swift.Void)? = nil,
                                file: StaticString = #file,
                                line: UInt = #line) {
        assertAmbigousLayout(view, file: file, line: line)
        for width in phoneWidths() {
            verifyView(view: view,
                       extraLayoutPass: extraLayoutPass,
                       width: width,
                       tolerance: tolerance,
                       configuration: configuration,
                       file: file,
                       line: line)
        }
    }

    func verifyView(view: UIView,
                    extraLayoutPass: Bool = false,
                    width: CGFloat,
                    tolerance: CGFloat = 0,
                    configuration: ((UIView) -> Swift.Void)? = nil,
                    file: StaticString = #file,
                    line: UInt = #line
        ) {
        let container = containerView(with: view)

        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: width)
            ])

        container.layoutIfNeeded()

        if assertEmptyFrame(container, file: file, line: line) {
            return
        }

        configuration?(view)

        if extraLayoutPass {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        view.layer.speed = 0 // freeze animations for deterministic tests
        snapshotVerify(view: container,
                       identifier:"\(Int(width))",
            tolerance: tolerance,
            file: file,
            line: line)
    }
}

// MARK: - Helpers

extension ZMSnapshotTestCase {
    func snapshotVerify(view: UIView,
                        identifier: String? = nil,
                        suffix: NSOrderedSet? = FBSnapshotTestCaseDefaultSuffixes(),
                        tolerance: CGFloat = 0,
                        file: StaticString = #file,
                        line: UInt = #line) {
        if let errorDescription = snapshotVerifyViewOrLayer(view,
                                                            identifier: identifier,
                                                            suffixes: suffix,
                                                            tolerance: tolerance, defaultReferenceDirectory: (FB_REFERENCE_IMAGE_DIR)) {

            XCTFail("\(errorDescription)", file:file, line:line)
        } else {
            XCTAssert(true)
        }
    }


    func assertEmptyFrame(_ view: UIView,
                          file: StaticString = #file,
                          line: UInt = #line) -> Bool {
        if view.frame.isEmpty {
            let description = "View frame can not be empty"
            let filePath = "\(file)"
            recordFailure(withDescription: description, inFile: filePath, atLine: Int(line), expected: true)
            return true
        }
        return false
    }



    func containerView(with view: UIView) -> UIView {
        let container = UIView(frame: view.bounds)
        container.backgroundColor = snapshotBackgroundColor
        container.addSubview(view)

        view.fitInSuperview()
        view.translatesAutoresizingMaskIntoConstraints = false
        return container
    }

    func phoneWidths() -> Set<CGFloat> {
        return Set(phoneSizes().map( { boxedSize in
            return boxedSize.cgSizeValue.width
        }))
    }

    func phoneSizes() -> [NSValue] {
        return [NSValue(cgSize: XCTestCase.ZMDeviceSizeIPhone5),
                NSValue(cgSize: XCTestCase.ZMDeviceSizeIPhone6),
                NSValue(cgSize: XCTestCase.ZMDeviceSizeIPhone6Plus),
                NSValue(cgSize: XCTestCase.ZMDeviceSizeIPhoneX),     ///same size as iPhone Xs Max
            NSValue(cgSize: ZMSnapshotTestCase.ZMDeviceSizeIPhoneXR)]
    }

    func assertAmbigousLayout(_ view: UIView,
                              file: StaticString = #file,
                              line: UInt = #line) {
        if view.hasAmbiguousLayout,
            let trace = view._autolayoutTrace() {
            let description = "Ambigous layout in view: \(view) trace: \n\(trace)"

            recordFailure(withDescription: description, inFile: "\(file)", atLine: Int(line), expected: true)

        }
    }
}

extension ZMSnapshotTestCase {

    func verify(view: UIView, identifier: String = "", tolerance: Float = 0, file: StaticString = #file, line: UInt = #line) {
        verifyView(view, extraLayoutPass: false, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: identifier, deviceName: nil)
    }
    
    func verifyInAllDeviceSizes(view: UIView, file: StaticString = #file, line: UInt = #line, configuration: @escaping (UIView, Bool) -> () = { _, _ in }) {
        verifyInAllDeviceSizes(view: view, extraLayoutPass: false, file: file, line: line, configurationBlock: configuration)
    }

    func verifyInAllTabletWidths(view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllTabletWidths: view, extraLayoutPass: false, file: file.utf8SignedStart(), line: line)
    }


    func verifyInIPhoneSize(view: UIView, file: StaticString = #file, line: UInt = #line) {
        constrain(view) { view in
            view.width == defaultIPhoneSize.width
            view.height == defaultIPhoneSize.height
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        verifyView(view, extraLayoutPass: false, tolerance: 0, file: file.utf8SignedStart(), line: line, identifier: "", deviceName: nil)
    }
    
    func verifyInAllIPhoneSizes(view: UIView, extraLayoutPass: Bool = false, file: StaticString = #file, line: UInt = #line, configurationBlock: ((UIView) -> Swift.Void)? = nil) {
        verifyInAllPhoneSizes(view: view, extraLayoutPass: extraLayoutPass, file: file, line: line, configurationBlock: configurationBlock)
    }
    
    func verifyInAllColorSchemes(view: UIView, tolerance: Float = 0, file: StaticString = #file, line: UInt = #line) {
        if var themeable = view as? Themeable {
            themeable.colorSchemeVariant = .light
            snapshotBackgroundColor = .white
            verifyView(view, extraLayoutPass: false, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: "LightTheme", deviceName: nil)
            themeable.colorSchemeVariant = .dark
            snapshotBackgroundColor = .black
            verifyView(view, extraLayoutPass: false, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: "DarkTheme", deviceName: nil)
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
    func presentViewController(_ controller: UIViewController, file: StaticString = #file, line: UInt = #line) {
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
    }

    func dismissViewController(_ controller: UIViewController, file: StaticString = #file, line: UInt = #line) {
        let dismissalExpectation = expectation(description: "It should be dismissed")
        controller.dismiss(animated: false) {
            dismissalExpectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func verifyAlertController(_ controller: UIAlertController, file: StaticString = #file, line: UInt = #line) {
        presentViewController(controller, file: file, line: line)
        verify(view: controller.view, file: file, line: line)
    }
}
