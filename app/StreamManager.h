//
//  StreamManager.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectiveFlickr.h"
#import "PhotoStreamManager.h"

@interface StreamManager : PhotoStreamManager {
}

+(StreamManager *)sharedStreamManager;

-(void)loadCachedImageList;
-(void)saveCachedImageList;

@end


