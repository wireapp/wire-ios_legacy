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


import UIKit
import Cartography

final class WaveFormView: UIView {

    fileprivate let visualizationView = SCSiriWaveformView()
    fileprivate let leftGradient = GradientView()
    fileprivate let rightGradient = GradientView()
    
    fileprivate var leftGradientWidthConstraint: NSLayoutConstraint?
    fileprivate var rightGradientWidthConstraint: NSLayoutConstraint?
    
    var gradientWidth: CGFloat = 25 {
        didSet {
            leftGradientWidthConstraint?.constant = gradientWidth
            rightGradientWidthConstraint?.constant = gradientWidth
        }
    }
    
    var gradientColor: UIColor = UIColor.from(scheme: .background) {
        didSet {
            updateWaveFormColor()
        }
    }
    
    var color: UIColor? {
        didSet { visualizationView.waveColor = color }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        configureViews()
        updateWaveFormColor()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWithLevel(_ level: CGFloat) {
        visualizationView.update(withLevel: level)
    }
    
    fileprivate func configureViews() {
        [visualizationView, leftGradient, rightGradient].forEach(addSubview)
        
        visualizationView.primaryWaveLineWidth = 1
        visualizationView.secondaryWaveLineWidth = 0.5
        visualizationView.numberOfWaves = 4
        visualizationView.waveColor = .accent()
        visualizationView.backgroundColor = UIColor.clear
        visualizationView.phaseShift = -0.3
        visualizationView.frequency = 1.7
        visualizationView.density = 10
        visualizationView.update(withLevel: 0) // Make sure we don't show any waveform
        
        let (midLeft, midRight) = (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
        leftGradient.setStartPoint(midLeft, endPoint: midRight, locations: [0, 1])
        rightGradient.setStartPoint(midRight, endPoint: midLeft, locations: [0, 1])
    }
    
    fileprivate func createConstraints() {
        constrain(self, visualizationView, leftGradient, rightGradient) { view, visualizationView, leftGradient, rightGradient in
            visualizationView.edges == view.edges
            align(top: view, leftGradient, rightGradient)
            align(bottom: view, leftGradient, rightGradient)
            view.left == leftGradient.left
            view.right == rightGradient.right
            leftGradientWidthConstraint = leftGradient.width == gradientWidth
            rightGradientWidthConstraint = rightGradient.width == gradientWidth
        }
    }
    
    fileprivate func updateWaveFormColor() {
        let clearGradientColor = gradientColor.withAlphaComponent(0)
        let leftColors = [gradientColor, clearGradientColor].map { $0.cgColor }
        leftGradient.gradientLayer.colors = leftColors
        rightGradient.gradientLayer.colors = leftColors
    }
    
}
