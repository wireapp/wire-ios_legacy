/*
* Wire
* Copyright (C) 2016 Wire Swiss GmbH
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

typedef NS_ENUM(NSInteger, AVSAudioEffectType) {
        AVSAudioEffectTypeChorusMin,
        AVSAudioEffectTypeChorusMed,
        AVSAudioEffectTypeChorusMax,
        AVSAudioEffectTypeReverbMin,
        AVSAudioEffectTypeReverbMed,
        AVSAudioEffectTypeReverbMax,
        AVSAudioEffectTypePitchupMin,
        AVSAudioEffectTypePitchupMed,
        AVSAudioEffectTypePitchupMax,
        AVSAudioEffectTypePitchupInsane,
        AVSAudioEffectTypePitchdownMin,
        AVSAudioEffectTypePitchdownMed,
        AVSAudioEffectTypePitchdownMax,
        AVSAudioEffectTypePitchdownInsane,
        AVSAudioEffectTypePaceupMin,
        AVSAudioEffectTypePaceupMed,
        AVSAudioEffectTypePaceupMax,
        AVSAudioEffectTypePacedownMin,
        AVSAudioEffectTypePacedownMed,
        AVSAudioEffectTypePacedownMax,
        AVSAudioEffectTypeReverse,
        AVSAudioEffectTypeVocoderMin,
        AVSAudioEffectTypeVocoderMed,
        AVSAudioEffectTypeAutoTuneMin,
        AVSAudioEffectTypeAutoTuneMed,
        AVSAudioEffectTypeAutoTuneMax,
        AVSAudioEffectTypePitchUpDownMin,
        AVSAudioEffectTypePitchUpDownMed,
        AVSAudioEffectTypePitchUpDownMax,
        AVSAudioEffectTypeNone,
};

@protocol AVSAudioEffectProgressDelegate <NSObject>
@required

- (void)updateProgress: (double) progress;

@end


@interface AVSAudioEffect : NSObject

@property(nonatomic, assign) id <AVSAudioEffectProgressDelegate> delegate;

- (int)applyEffectWav:(id<AVSAudioEffectProgressDelegate>)delegate inFile: (NSString *)inWavFileName outFile: (NSString *)outWavFileName effect: (AVSAudioEffectType) effect nr_flag:(bool)reduce_noise;

@end


