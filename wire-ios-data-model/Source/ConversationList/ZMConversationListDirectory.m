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


#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationList+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString * const ConversationListDirectoryKey = @"ZMConversationListDirectoryMap";

static NSString * const AllKey = @"All";
static NSString * const UnarchivedKey = @"Unarchived";
static NSString * const ArchivedKey = @"Archived";
static NSString * const PendingKey = @"Pending";



@interface ZMConversationListDirectory ()

@property (nonatomic) ZMConversationList* unarchivedConversations;
@property (nonatomic) ZMConversationList* conversationsIncludingArchived;
@property (nonatomic) ZMConversationList* archivedConversations;
@property (nonatomic) ZMConversationList* pendingConnectionConversations;
@property (nonatomic) ZMConversationList* clearedConversations;
@property (nonatomic) ZMConversationList* oneToOneConversations;
@property (nonatomic) ZMConversationList* groupConversations;
@property (nonatomic) ZMConversationList* favoriteConversations;

@property (nonatomic, readwrite) NSMutableDictionary<NSManagedObjectID *, ZMConversationList *> *listsByFolder;
@property (nonatomic) FolderList *folderList;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end



@implementation ZMConversationListDirectory

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
        
        NSArray *allConversations = [self fetchAllConversations:moc];
        NSArray *allFolders = [self fetchAllFolders:moc];
        
        self.folderList = [[FolderList alloc] initWithLabels:allFolders];
        self.listsByFolder = [self createListsFromFolders:allFolders allConversations:allConversations];

        self.unarchivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                         filteringPredicate:ZMConversation.predicateForConversationsExcludingArchived
                                                                                        moc:moc
                                                                                description:@"unarchivedConversations"];
        self.archivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:ZMConversation.predicateForArchivedConversations
                                                                                      moc:moc
                                                                              description:@"archivedConversations"];
        self.conversationsIncludingArchived = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:ZMConversation.predicateForConversationsIncludingArchived
                                                                                               moc:moc
                                                                                       description:@"conversationsIncludingArchived"];
        self.pendingConnectionConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:ZMConversation.predicateForPendingConversations
                                                                                               moc:moc
                                                                                  description:@"pendingConnectionConversations"];
        self.clearedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                      filteringPredicate:ZMConversation.predicateForClearedConversations
                                                                                     moc:moc
                                                                             description:@"clearedConversations"];
        
        self.oneToOneConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:ZMConversation.predicateForOneToOneConversations
                                                                                      moc:moc
                                                                              description:@"oneToOneConversations"];
        
        self.groupConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                    filteringPredicate:ZMConversation.predicateForGroupConversations
                                                                                   moc:moc
                                                                           description:@"groupConversations"];
        
        self.favoriteConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:[ZMConversation predicateForLabeledConversations:[Label fetchFavoriteLabelIn:moc]]
                                                                                      moc:moc description:@"favorites"];
    }
    return self;
}

- (NSArray *)fetchAllConversations:(NSManagedObjectContext *)context
{
    NSFetchRequest *allConversationsRequest = [ZMConversation sortedFetchRequest];
    // Since this is extremely likely to trigger the "participantRoles" and "connection" relationships, we make sure these gets prefetched:
    NSMutableArray *keyPaths = [NSMutableArray arrayWithArray:allConversationsRequest.relationshipKeyPathsForPrefetching];
    [keyPaths addObject:ZMConversationParticipantRolesKey];
    [keyPaths addObject:ZMConversationConnectionKey];
    allConversationsRequest.relationshipKeyPathsForPrefetching = keyPaths;
    
    NSError *error;
    return [context executeFetchRequest:allConversationsRequest error:&error];
    NSAssert(error != nil, @"Failed to fetch");
}

- (NSArray *)fetchAllFolders:(NSManagedObjectContext *)context
{
    return [context executeFetchRequestOrAssert:[Label sortedFetchRequest]];
}

- (NSMutableDictionary *)createListsFromFolders:(NSArray<Label *> *)folders allConversations:(NSArray<ZMConversation *> *)allConversations
{
    NSMutableDictionary *listsByFolder = [NSMutableDictionary new];

    for (Label *folder in folders) {
        listsByFolder[folder.objectID] = [self createListForFolder:folder allConversations:allConversations];
    }
    
    return listsByFolder;
}

- (ZMConversationList *)createListForFolder:(Label *)folder allConversations:(NSArray<ZMConversation *> *)allConversations
{
    return [[ZMConversationList alloc] initWithAllConversations:allConversations
                                             filteringPredicate:[ZMConversation predicateForLabeledConversations:folder]
                                                            moc:self.managedObjectContext
                                                    description:folder.objectIDURLString
                                                          label:folder];
}

- (void)insertFolders:(NSArray<Label *> *)labels
{
    if (labels.count == 0) {
        return;
    }
    
    NSArray<ZMConversation *> *allConversations = [self fetchAllConversations:self.managedObjectContext];
    for (Label *label in labels) {        
        ZMConversationList *folderList = [self createListForFolder:label allConversations:allConversations];
        self.listsByFolder[label.objectID] = folderList;
        [self.folderList insertLabel:label];
    }
}

- (void)deleteFolders:(NSArray<Label *> *)labels
{
    if (labels.count == 0) {
        return;
    }
    
    for (Label *label in labels) {
        [self.listsByFolder removeObjectForKey:label.objectID];
        [self.folderList removeLabel:label];
    }
}

- (void)refetchAllListsInManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSArray *allConversations = [self fetchAllConversations:moc];
    for (ZMConversationList* list in self.allConversationLists){
        [list recreateWithAllConversations:allConversations];
    }
    
    NSArray *allFolders = [self fetchAllFolders:moc];
    self.folderList = [[FolderList alloc] initWithLabels:allFolders];
    self.listsByFolder = nil;
    self.listsByFolder = [self createListsFromFolders:allFolders allConversations:allConversations];
}

- (NSArray *)allConversationLists;
{
    return @[
             self.pendingConnectionConversations,
             self.archivedConversations,
             self.conversationsIncludingArchived,
             self.unarchivedConversations,
             self.clearedConversations,
             self.oneToOneConversations,
             self.groupConversations,
             self.favoriteConversations
             ];
}

- (NSArray<id<LabelType>> *)allFolders
{
    return self.folderList.backingList;
}

@end



@implementation NSManagedObjectContext (ZMConversationListDirectory)

- (ZMConversationListDirectory *)conversationListDirectory;
{
    ZMConversationListDirectory *directory = self.userInfo[ConversationListDirectoryKey];
    if (directory == nil) {
        directory = [[ZMConversationListDirectory alloc] initWithManagedObjectContext:self];
        self.userInfo[ConversationListDirectoryKey] = directory;
    }
    return directory;
}

@end


