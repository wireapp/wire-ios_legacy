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
//// Copyright (C) 2013 Stefan Ceriu
////
//// Permission is hereby granted, free of charge, to any person obtaining a copy of this
//// software and associated documentation files (the "Software"), to deal in the Software
//// without restriction, including without limitation the rights to use, copy, modify, merge,
//// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//// to whom the Software is furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in all copies or substantial
//// portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
//// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SCSiriWaveformView.h"

static const CGFloat kDefaultFrequency          = 1.5f;
static const CGFloat kDefaultAmplitude          = 1.0f;
static const CGFloat kDefaultIdleAmplitude      = 0.01f;
static const CGFloat kDefaultNumberOfWaves      = 5.0f;
static const CGFloat kDefaultPhaseShift         = -0.15f;
static const CGFloat kDefaultDensity            = 5.0f;
static const CGFloat kDefaultPrimaryLineWidth   = 3.0f;
static const CGFloat kDefaultSecondaryLineWidth = 1.0f;

@interface SCSiriWaveformView ()

@property (nonatomic, assign) CGFloat phase;
@property (nonatomic, assign) CGFloat amplitude;

@end

@implementation SCSiriWaveformView

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setup];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		[self setup];
	}
	
	return self;
}

- (void)setup
{
	self.waveColor = [UIColor whiteColor];
	
	self.frequency = kDefaultFrequency;
	
	self.amplitude = kDefaultAmplitude;
	self.idleAmplitude = kDefaultIdleAmplitude;
	
	self.numberOfWaves = kDefaultNumberOfWaves;
	self.phaseShift = kDefaultPhaseShift;
	self.density = kDefaultDensity;
	
	self.primaryWaveLineWidth = kDefaultPrimaryLineWidth;
	self.secondaryWaveLineWidth = kDefaultSecondaryLineWidth;
}

- (void)updateWithLevel:(CGFloat)level
{
	self.phase += self.phaseShift;
	self.amplitude = fmax(level, self.idleAmplitude);
	
	[self setNeedsDisplay];
}

// Thanks to Raffael Hannemann https://github.com/raffael/SISinusWaveView
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, self.bounds);
	
	[self.backgroundColor set];
	CGContextFillRect(context, rect);
	
	// We draw multiple sinus waves, with equal phases but altered amplitudes, multiplied by a parable function.
	for (NSUInteger i = 0; i < self.numberOfWaves; i++) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextSetLineWidth(context, (i == 0 ? self.primaryWaveLineWidth : self.secondaryWaveLineWidth));
		
		CGFloat halfHeight = CGRectGetHeight(self.bounds) / 2.0f;
		CGFloat width = CGRectGetWidth(self.bounds);
		CGFloat mid = width / 2.0f;
		
		const CGFloat maxAmplitude = halfHeight - 4.0f; // 4 corresponds to twice the stroke width
		
		// Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
		CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
		CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
		
		CGFloat multiplier = MIN(1.0, (progress / 3.0f * 2.0f) + (1.0f / 3.0f));
		[[self.waveColor colorWithAlphaComponent:multiplier * CGColorGetAlpha(self.waveColor.CGColor)] set];
		
		for (CGFloat x = 0; x<width + self.density; x += self.density) {
			// We use a parable to scale the sinus wave, that has its peak in the middle of the view.
			CGFloat scaling = -pow(1 / mid * (x - mid), 2) + 1;
			
			CGFloat y = scaling * maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
			
			if (x == 0) {
				CGContextMoveToPoint(context, x, y);
			} else {
				CGContextAddLineToPoint(context, x, y);
			}
		}
		
		CGContextStrokePath(context);
	}
}

@end
