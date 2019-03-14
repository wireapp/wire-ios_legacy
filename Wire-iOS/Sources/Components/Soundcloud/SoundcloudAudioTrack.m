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


#import "SoundcloudAudioTrack.h"
#import "SoundcloudAudioTrack+Internal.h"
#import "SoundcloudService.h"



@interface SoundcloudAudioTrack ()

@property (nonatomic) SoundcloudService *soundcloudService;
@property (nonatomic) NSURL *avatarURL;

@end



@implementation SoundcloudAudioTrack

@synthesize title = _title;
@synthesize author = _author;
@synthesize artworkURL = _artworkURL;
@synthesize externalURL = _externalURL;
@synthesize duration = _duration;
@synthesize failedToLoad = _failedToLoad;


static NSURL* NSURLFromObject(id object) {
    return [object isKindOfClass:[NSString class]] ? [NSURL URLWithString:(NSString *)object] : nil;
}

static CGFloat CGFloatFromObject(id object) {
    return [object isKindOfClass:[NSNumber class]] ? [(NSNumber *)object doubleValue] : 0;
}

static NSDictionary* NSDictionaryFromObject(id object) {
    return [object isKindOfClass:[NSDictionary class]] ? object : nil;
}

+ (SoundcloudAudioTrack *)audioTrackFromJSON:(NSDictionary *)JSON soundcloudService:(SoundcloudService *)soundcloudService
{
    return [[self alloc] initWithJSON:JSON soundcloudService:soundcloudService];
}

- initWithJSON:(NSDictionary *)JSON soundcloudService:(SoundcloudService *)soundcloudService
{
    self = [super init];
    
    if (self) {
        _soundcloudService = soundcloudService;
        _title = JSON[@"title"];
        _author = [NSDictionaryFromObject(JSON[@"user"]) valueForKey:@"username"];
        _duration = CGFloatFromObject(JSON[@"duration"]) / 1000.f;
        _externalURL = NSURLFromObject([JSON valueForKeyPath:@"permalink_url"]);
        _artworkURL = NSURLFromObject([JSON valueForKeyPath:@"artwork_url"]);
        _avatarURL = NSURLFromObject([NSDictionaryFromObject(JSON[@"user"]) valueForKey:@"avatar_url"]);
        _internalStreamURL = NSURLFromObject(JSON[@"stream_url"]);
        _trackId = JSON[@"id"];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[SoundcloudAudioTrack class]]) {
        return NO;
    }
    
    return [self isEqualToSoundcloudAudioTrack:object];
}

- (BOOL)isEqualToSoundcloudAudioTrack:(SoundcloudAudioTrack *)soundcloudAudioTrack
{
    return [self.internalStreamURL isEqual:soundcloudAudioTrack.internalStreamURL];
}

- (NSURL *)artworkURL
{
    NSURL *URL = _artworkURL;
    
    if (_artworkURL == nil) {
        URL = self.avatarURL;
    }
    
    return [self.class imageResourceURL:URL withSize:@"crop"];
}

- (NSURL *)streamURL
{
    return self.resolvedStreamURL;
}

+ (NSURL *)imageResourceURL:(NSURL *)URL withSize:(NSString *)size
{
    return [NSURL URLWithString:[[URL absoluteString] stringByReplacingOccurrencesOfString:@"large" withString:size]];
}

- (void)fetchArtwork
{
    [[[NSURLSession sharedSession] dataTaskWithURL:self.artworkURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (! error && data != nil) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.artwork = image;
            });
        }
    }] resume];
}

@end

@implementation SoundcloudPlaylist

@synthesize title = _title;
@synthesize author = _author;
@synthesize tracks = _tracks;
@synthesize externalURL = _externalURL;

+ (SoundcloudPlaylist *)audioPlaylistFromJSON:(NSDictionary *)JSON soundcloudService:(SoundcloudService *)soundcloudService
{
    return [[self alloc] initWithJSON:JSON soundcloudService:soundcloudService];
}

- initWithJSON:(NSDictionary *)JSON soundcloudService:(SoundcloudService *)soundcloudService
{
    self = [super init];
    
    if (self) {
        _title = JSON[@"title"];
        _author = [NSDictionaryFromObject(JSON[@"user"]) valueForKey:@"username"];
        _externalURL = NSURLFromObject([JSON valueForKeyPath:@"permalink_url"]);
        
        NSMutableArray *tracks = [NSMutableArray array];
        
        id JSONTracks = JSON[@"tracks"];
        if ([JSONTracks conformsToProtocol:@protocol(NSFastEnumeration)]) {
            for (NSDictionary *track in JSONTracks) {
                [tracks addObject:[SoundcloudAudioTrack audioTrackFromJSON:track soundcloudService:soundcloudService]];
            }
        }
                
        _tracks = [tracks copy];
    }
    
    return self;
}

@end
