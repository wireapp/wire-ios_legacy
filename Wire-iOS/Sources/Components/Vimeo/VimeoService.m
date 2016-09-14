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


#import "VimeoService.h"
#import "MediaPreviewView.h"
#import "MediaPreviewData+Vimeo.h"

@import VIMNetworkingFramework;



static NSString * const VimeoScopePublic = @"public";
static const NSUInteger MaxRetryCount = 3;



@interface VimeoService ()

@property (nonatomic) VIMSession *session;

@end



@implementation VimeoService

+ (instancetype)sharedInstance
{
    static VimeoService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *clientKey = @STRINGIZE(VIMEO_API_KEY);
        NSString *secret = @STRINGIZE(VIMEO_API_SECRET);
        
        if (clientKey.length > 0 && secret.length > 0) {
            sharedInstance = [[self alloc] initWithClientKey:clientKey
                                                clientSecret:secret];
        }
    });
    
    return sharedInstance;
}

- (instancetype)initWithClientKey:(NSString *)clientKey clientSecret:(NSString *)clientSecret;
{
    self = [super init];
    
    if (self) {
        VIMSessionConfiguration *config = [[VIMSessionConfiguration alloc] init];
        
        config.clientKey = clientKey;
        config.clientSecret = clientSecret;
        config.scope = VimeoScopePublic;
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        
        config.keychainAccessGroup = [NSString stringWithFormat:@"%@%@", infoDict[@"AppIdentifierPrefix"], infoDict[@"CFBundleIdentifier"]];
        config.keychainService = @"com.wire.vimeo";
        
        [VIMSession setupWithConfiguration:config];
        
        self.session = [VIMSession sharedSession];
        
        if (! self.session.account.isAuthenticated) {
            [self.session authenticateWithClientCredentialsGrant:^(NSError *error) {
                DDLogVerbose(@"VIMAPIClient authenticateWithClientCredentialsGrant: error: %@", error);
            }];
        }
    }
    
    return self;
}

#pragma mark - Data Loading

- (void)mediaPreviewDataForVimeoVideoURL:(NSURL *)URL completion:(void (^)(MediaPreviewData *, NSError *))completion
{
    NSString *videoID = URL.lastPathComponent;
    [self mediaPreviewDataForVimeoVideoID:videoID retryCount:0 completion:completion];
}

- (void)mediaPreviewDataForVimeoVideoID:(NSString *)videoID retryCount:(NSUInteger)retryCount completion:(void (^)(MediaPreviewData *, NSError *))completion
{
    
    NSString *mediaPath = [NSString stringWithFormat:@"/videos/%@", videoID];
    [self.session.client videoWithURI:mediaPath completionBlock:^(VIMServerResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([response.urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                // Sometimes just after first auth server can still response in 401, so added retry logic here
                if ([(NSHTTPURLResponse *)response.urlResponse statusCode] == 401 && retryCount < MaxRetryCount) {
                    [self mediaPreviewDataForVimeoVideoID:videoID retryCount:retryCount + 1 completion:completion];
                }
            }
            
            if (error != nil) {
                completion(nil, error);
            } else {
                completion([[MediaPreviewData alloc] initWithVimeoVideo:(VIMVideo *)response.result], nil);
            }
        });
    }];
}

@end
