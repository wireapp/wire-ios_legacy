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


#import "ZMUserSession+iOS.h"
#import "ZMUserSession+RequestProxy.h"
#import "SoundcloudService.h"
#import "SoundcloudAudioTrack.h"
#import "SoundcloudService+Testing.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface SoundcloudService ()
@property (nonatomic, weak) ZMUserSession *userSession;
@end



@implementation SoundcloudService

+ (instancetype)sharedInstance
{
    static SoundcloudService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SoundcloudService alloc] initWithUserSession:nil];
    });
    
    return sharedInstance;
}

- (instancetype)initWithUserSession:(ZMUserSession *)userSession
{
    self = [super init];
    if (self != nil) {
        self.userSession = userSession;
    }
    return self;
}

- (ZMUserSession *)userSession
{
    return _userSession ?: [ZMUserSession sharedSession];
}

- (void)loadAudioResourceFromURL:(NSURL *)URL completion:(void (^)(id audioResource, NSError *error))completion
{
    NSString *resourcePath = [NSString stringWithFormat:@"/resolve?url=%@", URL.absoluteString];
    [self.userSession doRequestWithPath:resourcePath method:ZMMethodGET type:ProxiedRequestTypeSoundcloud completionHandler:[self responseHandlerWithCompletionHandler:completion]];
}

- (void (^)(NSData *data, NSURLResponse *response, NSError *error))responseHandlerWithCompletionHandler:(void (^)(id audioResource, NSError *error))completionHandler
{
    return ^(NSData *data, NSURLResponse *response, NSError *error) {
        id audioObject = nil;
        
        void (^reportError)(void) = ^{
            ZMLogError(@"Error: %@, %@", response, error);
            
            if (completionHandler) {
                completionHandler(audioObject, error);
            }
        };
        
        if (![response isKindOfClass:[NSHTTPURLResponse class]] || error != nil) {
            reportError();
            return;
        }
        
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        
        if (HTTPResponse.statusCode >= 300 || HTTPResponse.statusCode < 200) {
            reportError();
            return;
        }
        
        if (data == nil) {
            reportError();
            return;
        }
        
        audioObject = [self audioObjectFromData:data response:response];
        
        NSArray *tracks = nil;
        if ([audioObject isKindOfClass:[SoundcloudAudioTrack class]]) {
            tracks = @[audioObject];
        }
        else if ([audioObject isKindOfClass:[SoundcloudPlaylist class]]){
            tracks = [(SoundcloudPlaylist *)audioObject tracks];
        }
        
        dispatch_group_t processingGroup = dispatch_group_create();
        
        for (SoundcloudAudioTrack *track in tracks) {
            if (track.internalStreamURL.absoluteString.length == 0) {
                track.failedToLoad = YES;
                continue;
            }
            
            // fetch stream URL is reachable
            dispatch_group_enter(processingGroup);
            [self fetchStreamLocationForTrack:track completion:^(NSError *checkError) {
                if (track.resolvedStreamURL == nil || error != nil) {
                    track.failedToLoad = YES;
                }
                if (track.resolvedStreamURL == nil && error == nil) {
                    track.internalStreamURL = nil;
                }
                dispatch_group_leave(processingGroup);
            }];
        }
        
        dispatch_group_notify(processingGroup, dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(audioObject, error);
            }
        });
    };
}

- (void)fetchStreamLocationForTrack:(SoundcloudAudioTrack *)track completion:(void(^)(NSError *checkError))completion
{
    [self.userSession doRequestWithPath:[NSString stringWithFormat:@"/stream?url=%@", track.internalStreamURL.absoluteString]
                                 method:ZMMethodGET
                                   type:ProxiedRequestTypeSoundcloud
                      completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
                          if (error == nil) {
                              if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                  NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
                                  
                                  if (HTTPResponse.statusCode < 400) {
                                      NSString *location = HTTPResponse.allHeaderFields[@"Location"];
                                      if (location != nil) {
                                          track.resolvedStreamURL = [NSURL URLWithString:location];
                                      }
                                  }
                              }
                              else {
                                  error = [NSError errorWithDomain:@"SoundcloudServiceDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Request returned unexpected response type."}];
                              }
                          }
                          
                          if (completion) {
                              completion(error);
                          }
    }];
}

- (id)audioObjectFromData:(NSData *)data response:(NSURLResponse *)response
{
    if (data.length == 0) {
        return nil;
    }
    
    NSError *error = nil;
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error != nil || ![JSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSString *resource = nil;
    if (response.URL.pathComponents.count > 3) {
        resource = response.URL.pathComponents[3];
    }
    
    if ([resource isEqualToString:@"tracks"]) {
        return [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:self];
    }
    else if ([resource isEqualToString:@"playlists"]) {
        return [SoundcloudPlaylist audioPlaylistFromJSON:JSON soundcloudService:self];
    }
    else if ([resource isEqualToString:@"resolve"]) {
        if (JSON[@"tracks"] != NULL) {
            return [SoundcloudPlaylist audioPlaylistFromJSON:JSON soundcloudService:self];
        }
        else {
            return [SoundcloudAudioTrack audioTrackFromJSON:JSON soundcloudService:self];
        }
    }
    
    return nil;
}

@end
