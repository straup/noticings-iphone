//
//  StreamPhotoViewCell.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhotoViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "NoticingsAppDelegate.h"

@implementation StreamPhotoViewCell
@synthesize photo = _photo;

#define MAX_IMAGE_HEIGHT 320


-(void) populateFromPhoto:(StreamPhoto*)setphoto;
{
    DLog(@"populateFromPhoto %@", setphoto);
    
    // drop shadow on the white photo background
//    frameView.layer.shadowOffset = CGSizeMake(0,2);
//    frameView.layer.shadowColor = [[UIColor blackColor] CGColor];
//    frameView.layer.shadowRadius = 5.0f;
//    frameView.layer.shadowOpacity = 0.6f;
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.6f alpha:1.0f];

    if (self.photo == setphoto) {
        return;
    }


    self.photo = setphoto;

    titleView.text = self.photo.title;
    usernameView.text = self.photo.ownername;

    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:self.photo.ago];

    hasLocationImage.hidden = !self.photo.hasLocation;

    int vis = self.photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
        privacyImage.image = [UIImage imageNamed:@"visibility_red"];
    } else if (vis == StreamPhotoVisibilityLimited) {
        privacyImage.image = [UIImage imageNamed:@"visibility_yellow"];
    } else if (vis == StreamPhotoVisibilityPublic) {
        privacyImage.image = [UIImage imageNamed:@"visibility_green"];
    }
    
    avatarView.image = [UIImage imageNamed:@"235-person"];
    photoView.image = [UIImage imageNamed:@"photos"];
    photoView.contentMode = UIViewContentModeCenter;

    __block StreamPhotoViewCell* _self = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [[[NSData alloc] initWithContentsOfURL:self.photo.imageURL] autorelease];
        UIImage * image = [[[UIImage alloc] initWithData:data] autorelease];
        if (image != nil) {
            dispatch_async( dispatch_get_main_queue(), ^{
                if (_self.photo == setphoto) {
                    photoView.image = image;

                    // make landscape images aspect fill and crop to frame, so we get perfect margins.
                    // or actually, images that are close enough to landscape that we'd get ugly margins.
                    if ([_self.photo imageHeightForWidth:320] <= MAX_IMAGE_HEIGHT) {
                        photoView.contentMode = UIViewContentModeScaleAspectFill;
                    } else {
                        photoView.contentMode = UIViewContentModeScaleAspectFit;
                    }
                }
            });
        }
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [[[NSData alloc] initWithContentsOfURL:self.photo.avatarURL] autorelease];
        UIImage * image = [[[UIImage alloc] initWithData:data] autorelease];
        if (image != nil) {
            dispatch_async( dispatch_get_main_queue(), ^{
                if (_self.photo == setphoto) {
                    avatarView.image = image;
                }
            });
        }
    });

    // all the views in the nib have the right affinity to edges and know how to scale
    // themselves, so we just have to resize the outer frame and re-lay them out.
    CGRect frame = self.frame;
    frame.size.height = [StreamPhotoViewCell cellHeightForPhoto:self.photo];
    self.frame = frame;
    
}

+(CGFloat)cellHeightForPhoto:(StreamPhoto*)photo;
{
    // the desired height of the cell is the height of the photo plus the height of the controls.
    // all we need to do is get the outer frame right - everything else lays itself out properly.
    // In theory, we need to be _perfect_ here - too tall or wide and images won't have the right 
    // margins. In practice, this turns out to be hard (Why?) so I cheat be flipping the image view
    // to "aspect fill" for landscape images, so as long as we're within 1% here everything looks
    // fine.
    
    CGFloat controls = 80;

    // ideal image height, limited to a maximum so images don't make cells bigger than the window.
    CGFloat wantedImageHeight = MIN( [photo imageHeightForWidth:320], MAX_IMAGE_HEIGHT);
    
    return wantedImageHeight + controls;
}

-(void) gotLocation:(NSString*)location forPhoto:(StreamPhoto*)photo;
{
    // note that this cell can be re-used, so don't overwrite the wrong location.
    if ([photo.woeid isEqual:self.photo.woeid]) {
        //placeView.text = [@"⊙" stringByAppendingString:location];
    }
}

- (void)dealloc {
    self.photo = nil;
    [super dealloc];
}


@end
