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


#import "GiphySearchResultsController.h"
#import "ziphy+iOS.h"

@interface GiphySearchResultsController ()

@property (nonatomic, strong, readwrite) ZiphyClient *ziphyClient;
@property (nonatomic, copy, readwrite) NSString *searchTerm;
@property (nonatomic, readwrite) ZiphyImageType imageType;
@property (nonatomic, readwrite) NSInteger pageSize;
@property (nonatomic, readwrite) NSInteger maxImageSize;
@property (nonatomic, readwrite) NSInteger totalPagesFetched;

@property (nonatomic, readwrite) BOOL isFetchingNewPage;
@property (nonatomic, readwrite) NSError *fetchPageError;

@property (nonatomic) ZiphySearchResultsController *ziphySearchResultsController;
@property (nonatomic, readwrite) NSArray *searchResults;

@end


@implementation GiphySearchResultsController

- (instancetype)initWithSearchTerm:(NSString *)searchTerm
                         imageType:(ZiphyImageType)imageType
                          pageSize:(NSInteger)pageSize
                      maxImageSize:(NSInteger)imageSize
{
    self = [super init];
    if (self) {
        
        self.searchTerm = searchTerm;
        self.imageType = imageType;
        self.pageSize = pageSize;
        self.maxImageSize = imageSize;
        self.ziphyClient = [ZiphyClient wr_ziphyWithDefaultConfiguration];
        self.ziphySearchResultsController = [[ZiphySearchResultsController alloc] initWithSearchTerm:self.searchTerm
                                                                                            pageSize:self.pageSize
                                                                                       callBackQueue:(OS_dispatch_queue *)dispatch_get_main_queue()];
        self.ziphySearchResultsController.ziphyClient = self.ziphyClient;
        self.searchResults = [NSArray array];
    }
    
    return self;
}

- (NSInteger)numberOfResultsLastFetch
{
    return self.ziphySearchResultsController.resultsLastFetch;
}

-(void)fetchNewPage:(void (^)(BOOL, NSError *))onCompletion
{
    self.isFetchingNewPage = YES;
    self.fetchPageError = nil;
    
    [self.ziphySearchResultsController fetchSearchResults:^(BOOL success, NSError * error) {
        
        if (success){
            
            [self filterResultsBySize];
        }else {
            self.fetchPageError = error;
        }
        
        self.isFetchingNewPage = NO;
        
        if (onCompletion) {
            onCompletion(success, error);
        }
        
    }];
}

- (void)filterResultsBySize
{
    
    NSString *dictionaryKey = [ZiphyClient fromZiphyImageTypeToString:self.imageType];
    
    NSPredicate *filterBySizePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        
        Ziph *ziph = (Ziph *)evaluatedObject;
        
        ZiphyImageRep *ziphyImageRep = ziph.ziphyImages[dictionaryKey];
        return ziphyImageRep.size <= self.maxImageSize;
        
    }];
    
    NSArray *ziphsfilteredBySize = [self.ziphySearchResultsController.results filteredArrayUsingPredicate:filterBySizePredicate];
    
    self.totalPagesFetched = self.ziphySearchResultsController.totalPagesFetched;
    self.searchResults = ziphsfilteredBySize;
}

- (void)fetchImageForSearchResult:(Ziph *)ziph
                           ofType:(ZiphyImageType)imageType
                       completion:(void (^)(BOOL success, ZiphyImageRep *ziphyImageRep, Ziph *ziph, NSData *imageData, NSError *error))completion
{
    [self.ziphyClient  fetchImage:(OS_dispatch_queue *)dispatch_get_main_queue()
                            ziph:ziph
                       imageType:imageType
                    onCompletion:completion];
}

@end
