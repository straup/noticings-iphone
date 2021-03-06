//
//  UploadQueueManager.h
//  Noticings
//
//  Created by Tom Taylor on 18/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoUpload.h"
#import "APIKeys.h"

@interface UploadQueueManager : NSObject

- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload;
- (void)cancelUpload:(PhotoUpload*)upload;
- (void)resumeUpload:(PhotoUpload*)upload;
- (void)saveQueuedUploads;
- (void)restoreQueuedUploads;
- (void)fakeUpload;

// operation callbacks
- (void)uploadFailed:(PhotoUpload*)upload;
- (void)uploadSucceeded:(PhotoUpload*)upload;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableArray *uploads;



@end
