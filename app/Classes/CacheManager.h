//
//  CacheManager.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <Foundation/Foundation.h>

// protocol for delegates of loadImagefetchImageForURL:andNotify:
@protocol DeferredImageLoader <NSObject>
@required
-(void) loadedImage:(UIImage*)image forURL:(NSURL*)url cached:(BOOL)cached;
@end

@interface CacheManager : NSObject

- (NSString*) cachePathForFilename:(NSString*)filename;
- (UIImage *) cachedImageForURL:(NSURL*)url;
- (void) fetchImageForURL:(NSURL*)url andNotify:(NSObject <DeferredImageLoader>*)sender;
- (void) flushMemoryCache;
- (void) flushQueue;
- (void) clearCache;
- (NSString*) urlToFilename:(NSURL*)url;

@property (retain) NSString *cacheDir;
@property (retain) NSMutableDictionary *imageCache;
@property (retain) NSMutableDictionary *imageRequests;
@property (retain) NSOperationQueue *queue;


@end
