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


#import "VoiceGainLayer+MagicInit.h"
#import "WAZUIMagicIOS.h"
#import "PulseLayer.h"


@implementation VoiceGainLayer (MagicInit)

+ (instancetype)voiceGainLayerWithMagicIdentifier:(NSString *)identifier ringColor:(UIColor *)color
{
    VoiceGainLayer *layer = [VoiceGainLayer layer];
    NSDictionary *circles = [WAZUIMagic sharedMagic][identifier];

    for (NSDictionary *circle in circles) {
        PulseLayer *pulser = [PulseLayer layer];
        pulser.toOpacity = [circle[@"alpha"] floatValue];
        pulser.toContentScale = [circle[@"scale"] floatValue];
        pulser.backgroundColor = color.CGColor;
        [layer addSublayer:pulser];
    }
    return layer;

}

+ (instancetype)voiceGainLayerWithRingColor:(UIColor *)color
{
    return [[self class] voiceGainLayerWithMagicIdentifier:@"voice_overlay.voice_gain_tile_circles" ringColor:color];
}

- (void)updateCircleColor:(UIColor *)color
{
    for (PulseLayer *pulser in self.sublayers) {
        pulser.backgroundColor = color.CGColor;
    }
}

@end
