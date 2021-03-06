//
//  MapViewController.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>

#import "StreamPhoto.h"
#import "PhotoStreamManager.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate>

-(void)displayPhoto:(StreamPhoto*)_photo inManager:(PhotoStreamManager*)manager;

@property (strong) MKMapView *mapView;
@property (strong) StreamPhoto *photo;
@property (strong) PhotoStreamManager *streamManager;

@end
