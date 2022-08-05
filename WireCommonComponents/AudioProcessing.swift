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

/// Converts a 16 Bit PCM sample (i.e. from a linear scale) to a scalar between 0d and 1d (inclusive),
/// that represents the "loudness" (a bit like sone, but not frequency-adaptive). While both (input and output)
/// scales are linear, they are *not* directly proportional to each other.
public func scalar(_ amplitude: Int16) -> Double {
    return scalar(spl(min(max(minAmplitude, Double(amplitude)), maxAmplitude))) / maxScalar
}

private func scalar(_ spl: Double) -> Double {
    return pow(2, spl / 10.0)
}

private func spl(_ amplitude: Double) -> Double {
    return 20.0 * log10(pascal(amplitude)/minPascal)
}

private func pascal(_ amplitude: Double) -> Double {
    return abs(amplitude / ((amplitude < 0) ? minAmplitude : maxAmplitude)) * (maxPascal - minPascal) + minPascal
}

private let minAmplitude = Double(Int16.min)
private let maxAmplitude = Double(Int16.max)
private let minPascal = 2.0E-5 // hearing threshold
private let maxPascal = 0.632455532 // ca. 90 dB SPL
private let maxScalar = scalar(spl(maxAmplitude))
