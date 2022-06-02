//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

@import WireTesting;

@class ZMImagePreprocessingTracker;

@interface ZMImagePreprocessingTrackerTests : ZMTBaseTest

@property (nonatomic) id preprocessor;
@property (nonatomic) CoreDataStack *coreDataStack;
@property (nonatomic) NSOperationQueue *imagePreprocessingQueue;
@property (nonatomic) ZMImagePreprocessingTracker *sut;
@property (nonatomic) NSPredicate *fetchPredicate;
@property (nonatomic) NSPredicate *needsProcessingPredicate;

@property (nonatomic)  ZMClientMessage *linkPreviewMessage1;
@property (nonatomic)  ZMClientMessage *linkPreviewMessage2;
@property (nonatomic)  ZMClientMessage *linkPreviewMessage3;
@property (nonatomic)  ZMClientMessage *linkPreviewMessageExcludedByPredicate;

@end
