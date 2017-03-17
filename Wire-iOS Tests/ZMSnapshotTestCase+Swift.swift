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
import Classy


extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    public func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: self.bounds, style: .plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.layoutMargins = self.layoutMargins
        
        let size = self.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0.0) , withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityFittingSizeLevel)
        self.layoutSubviews()
        
        self.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        self.contentView.bounds = self.bounds
        
        tableView.reloadData()
        tableView.bounds = self.bounds
        tableView.layoutIfNeeded()
        
        constrain(tableView) { tableView in
            tableView.height == size.height
        }
        
        CASStyler.default().styleItem(self)
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

extension ZMSnapshotTestCase {
    func verify(view: UIView, identifier: String = "", tolerance: Float = 0, file: StaticString = #file, line: UInt = #line) {
        verifyView(view, extraLayoutPass: false, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: identifier)
    }
    
    func verifyInAllDeviceSizes(view: UIView, file: StaticString = #file, line: UInt = #line, configuration: @escaping (UIView, Bool) -> () = { _ in }) {
        verifyView(inAllDeviceSizes: view, extraLayoutPass: false, file: file.utf8SignedStart(), line: line, configurationBlock: configuration)
    }
    
    func verifyInAllPhoneWidths(view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllPhoneWidths: view, extraLayoutPass: false, file: file.utf8SignedStart(), line: line)
    }
    
    func verifyInAllTabletWidths(view: UIView, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllTabletWidths: view, extraLayoutPass: false, file: file.utf8SignedStart(), line: line)
    }
    
    func verifyInAllIPhoneSizes(view: UIView, extraLayoutPass: Bool = false, file: StaticString = #file, line: UInt = #line) {
        verifyView(inAllPhoneSizes: view, extraLayoutPass: extraLayoutPass, file: file.utf8SignedStart(), line: line, configurationBlock: nil)
    }
}
