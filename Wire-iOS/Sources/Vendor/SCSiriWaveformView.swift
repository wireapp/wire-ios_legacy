//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
// This module of the Wire Software uses software code from Stefan Ceriu
// governed by the MIT license (https://github.com/stefanceriu/SCSiriWaveformView).
//
//
//  SCSiriWaveformView.m
//  SCSiriWaveformView
//
//  Created by Stefan Ceriu on 12/04/2014.
//  Copyright (C) 2013 Stefan Ceriu.
//  Released under the MIT license.
//
//
// Copyright (C) 2013 Stefan Ceriu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
// to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

private let kDefaultFrequency: Float = 1.5
private let kDefaultAmplitude: Float = 1
private let kDefaultIdleAmplitude: Float = 0.01
private let kDefaultNumberOfWaves: UInt = 5
private let kDefaultPhaseShift: Float = -0.15
private let kDefaultDensity: Float = 5
private let kDefaultPrimaryLineWidth: CGFloat = 3
private let kDefaultSecondaryLineWidth: CGFloat = 1

final class SCSiriWaveformView: UIView {

    /*
     * The total number of waves
     * Default: 5
     */
    var numberOfWaves: UInt = 0
    /*
     * Color to use when drawing the waves
     * Default: white
     */
    var waveColor: UIColor = .white
    /*
     * Line width used for the proeminent wave
     * Default: 3f
     */
    var primaryWaveLineWidth: CGFloat = 0
    /*
     * Line width used for all secondary waves
     * Default: 1f
     */
    var secondaryWaveLineWidth: CGFloat = 0
    /*
     * The amplitude that is used when the incoming amplitude is near zero.
     * Setting a value greater 0 provides a more vivid visualization.
     * Default: 01
     */
    var idleAmplitude: Float = 0
    /*
     * The frequency of the sinus wave. The higher the value, the more sinus wave peaks you will have.
     * Default: 1.5
     */
    var frequency: Float = 0
    /*
     * The current amplitude
     */
    private(set) var amplitude: Float = 0
    /*
     * The lines are joined stepwise, the more dense you draw, the more CPU power is used.
     * Default: 5
     */
    var density: Float = 0
    /*
     * The phase shift that will be applied with each level setting
     * Change this to modify the animation speed or direction
     * Default: -0.15
     */
    var phaseShift: Float = 0

    private var phase: Float = 0

    init() {
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {

        frequency = kDefaultFrequency

        amplitude = kDefaultAmplitude
        idleAmplitude = kDefaultIdleAmplitude

        numberOfWaves = kDefaultNumberOfWaves
        phaseShift = kDefaultPhaseShift
        density = kDefaultDensity

        primaryWaveLineWidth = kDefaultPrimaryLineWidth
        secondaryWaveLineWidth = kDefaultSecondaryLineWidth
    }

    /*
     * Tells the waveform to redraw itself using the given level (normalized value)
     */
    func update(withLevel level: Float) {
        phase += phaseShift
        amplitude = fmax(level, idleAmplitude)

        setNeedsDisplay()
    }

    // Thanks to Raffael Hannemann https://github.com/raffael/SISinusWaveView

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.clear(bounds)

        backgroundColor?.set()
        context?.fill(rect)

        // We draw multiple sinus waves, with equal phases but altered amplitudes, multiplied by a parable function.
        let sinConst: Float = 2 * Float.pi * frequency

        let halfHeight: Float = Float(bounds.height) / 2
        let width: Float = Float(bounds.width)
        let maxAmplitude: Float = halfHeight - 4 // 4 corresponds to twice the stroke width
        let mid: Float = width / 2

        for i in 0..<numberOfWaves {
            let context = UIGraphicsGetCurrentContext()

            context?.setLineWidth((i == 0 ? primaryWaveLineWidth : secondaryWaveLineWidth))

            // Progress is a value between 1 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
            let progress: Float = 1 - Float(i) / Float(numberOfWaves)
            let normedAmplitude: Float = (1.5 * progress - 0.5) * amplitude

            let multiplier: Float = min(1, (progress / 3 * 2) + 1 / 3)
            waveColor.withAlphaComponent(CGFloat(multiplier) * waveColor.cgColor.alpha).set()

            var x: Float = 0
            while x < width + density {
                // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
                let scaling: Float = -pow(1 / mid * (x - mid), 2) + 1
                let sin: Float = sinf(sinConst * (x / width) + phase)
                let y: Float = scaling * maxAmplitude * normedAmplitude * sin + halfHeight

                let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
                if x == 0 {
                    context?.move(to: point)
                } else {
                    context?.addLine(to: point)
                }

                x += density
            }

            context?.strokePath()
        }
    }

}
