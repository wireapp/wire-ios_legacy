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

class AudioEffectsPickerViewControllerTests: ZMSnapshotTestCase {
    var sut: AudioEffectsPickerViewController! = .none
    
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    override func setUp() {
        super.setUp()
        
        let path = Bundle(for: type(of: self)).path(forResource: "audio_sample", ofType: "m4a")!
        self.sut = AudioEffectsPickerViewController(recordingPath: path, duration: TimeInterval(10.0))
        self.sut.normalizedLoudness = (0...100).map { Float($0) / 100.0 }
        self.sut.progressView.samples = self.sut.normalizedLoudness
    }
    
    func prepareForSnapshot() -> UIView {
        self.sut.beginAppearanceTransition(true, animated: false)
        self.sut.endAppearanceTransition()
        
        let container = UIView()
        container.addSubview(self.sut.view)
        container.backgroundColor = UIColor.from(scheme: .textForeground, variant: .light)

        constrain(self.sut.view, container) { view, container in
            container.height == 216
            container.width == 320
            view.top == container.top
            view.bottom == container.bottom
            view.left == container.left
            view.right == container.right
        }
        container.setNeedsLayout()
        container.layoutIfNeeded()
        return container
    }
    
    func testInitialState() {
        self.verify(view: self.prepareForSnapshot())
    }
    
    func testPlayingProgressState() {
        let preparedView = self.prepareForSnapshot()
        
        self.sut.setState(.playing, animated: false)
        self.verify(view: preparedView)
    }
    
    func testTooltipState() {
        let preparedView = self.prepareForSnapshot()
        self.sut.setState(.tip, animated: false)
        self.verify(view: preparedView)
    }
    
    func testEffectSelectedState() {
        let preparedView = self.prepareForSnapshot()

        self.sut.selectedAudioEffect = AVSAudioEffectType.chorusMax
        self.verify(view: preparedView)
    }
}
