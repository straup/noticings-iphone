//
//  PhotoMapViewController.m
//  Noticings
//
//  Created by Tom Taylor on 13/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoMapViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "UploadQueueManager.h"

enum {
    kUIAlertViewCurrentLocation,
    kUIAlertViewPreviousLocation,
    kUIAlertViewNoLocation
};

@implementation PhotoMapViewController

static NSString *adjustPinActionSheetCancelTitle = @"Cancel";
static NSString *adjustPinActionSheetOriginalLocationTitle = @"Original Location";
static NSString *adjustPinActionSheetCurrentLocationTitle = @"Current Location";
static NSString *adjustPinActionSheetPreviousLocationTitle = @"Last Uploaded Location";
static NSString *adjustPinActionSheetRemoveTitle = @"Remove from Map";
static NSString *adjustPinActionSheetAddTitle = @"Add to Map";

@synthesize mapView;
@synthesize mapTypeControl;
@synthesize photoUpload;
@synthesize toolbar;
@synthesize locationManager;
@synthesize currentLocation;
@synthesize previousLocation;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.showsUserLocation = NO;
	
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	[locationManager startUpdatingLocation];
	
	self.title = @"Location";
	
	UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] 
								   initWithTitle:@"Upload" 
								   style:UIBarButtonItemStyleDone
								   target:self
								   action:@selector(upload)];
	
	[[self navigationItem] setRightBarButtonItem:uploadButton];
	[uploadButton release];
		
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500);
        [self.mapView addAnnotation:self.photoUpload];
    } else {
        [self promptForLocation];
    }
}

- (void)promptForLocation {
    UIAlertView *alertView;
    if (self.currentLocation) {
        alertView = [[UIAlertView alloc] initWithTitle:@"No Location for Photo"
                                               message:@"Do you want to add the photo to the map at your current location?" 
                                              delegate:self
                                     cancelButtonTitle:nil 
                                     otherButtonTitles:@"Add at Current Location", @"Skip & Upload", nil];
        alertView.tag = kUIAlertViewCurrentLocation;
    } else if (self.previousLocation) {
        alertView = [[UIAlertView alloc] initWithTitle:@"No Location for Photo"
                                               message:@"Do you want to add the photo to the map at the last uploaded location?" 
                                              delegate:self 
                                     cancelButtonTitle:nil 
                                     otherButtonTitles:@"Add at Last Location", @"Skip & Upload", nil];
        alertView.tag = kUIAlertViewPreviousLocation;
    } else {
        alertView = [[UIAlertView alloc] initWithTitle:@"No Location for Photo"
                                               message:@"Do you want to add the photo to the map at your current location?" 
                                              delegate:self 
                                     cancelButtonTitle:nil 
                                     otherButtonTitles:@"Add at Current Location", @"Skip & Upload", nil];
        alertView.tag = kUIAlertViewNoLocation;
    }
    [alertView show];
    [alertView release];
}

#pragma mark -
#pragma mark MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if (annotation == mapView.userLocation) {
		return nil;
	}
	
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
	if (annotationView == nil) {
		annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"] autorelease];
	}
	
	annotationView.pinColor = MKPinAnnotationColorPurple;
	annotationView.animatesDrop = YES;
	annotationView.canShowCallout = NO;
	annotationView.draggable = YES;
	[annotationView setSelected:YES animated:NO];
	
	return annotationView;
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
	if ([UploadQueueManager sharedUploadQueueManager].inProgress == NO) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation
{
    // we remember the first location we get back from this, regardless of how old it might be
    if (self.previousLocation == nil) {
        self.previousLocation = newLocation;
        DLog(@"Setting previous location to: %@", self.previousLocation);
    }
    
	if (abs([newLocation.timestamp timeIntervalSinceDate: [NSDate date]]) < 120) {
		self.currentLocation = newLocation;
		DLog(@"Location updated to: %@", newLocation);
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Button actions

- (void)upload {
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
	[[NSUserDefaults standardUserDefaults] setFloat:coordinate.latitude forKey:@"lastKnownLatitude"];
	[[NSUserDefaults standardUserDefaults] setFloat:coordinate.longitude forKey:@"lastKnownLongitude"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[UploadQueueManager sharedUploadQueueManager] addPhotoUploadToQueue:self.photoUpload];
	[[UploadQueueManager sharedUploadQueueManager] startQueueIfNeeded];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)adjustPin:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Adjust Pin" 
                                                       delegate:self 
                                              cancelButtonTitle:adjustPinActionSheetCancelTitle
                                         destructiveButtonTitle:nil 
                                              otherButtonTitles:nil];

    if ([self.mapView.annotations containsObject:self.photoUpload]) {
        [sheet addButtonWithTitle:adjustPinActionSheetRemoveTitle];

        if (self.photoUpload.location) {
            [sheet addButtonWithTitle:adjustPinActionSheetOriginalLocationTitle];
        }
        
        if (self.currentLocation) {
            [sheet addButtonWithTitle:adjustPinActionSheetCurrentLocationTitle];
        }
        
        if (self.previousLocation) {
            [sheet addButtonWithTitle:adjustPinActionSheetPreviousLocationTitle];
        }
    
    } else {
        [sheet addButtonWithTitle:adjustPinActionSheetAddTitle];
    }
	
	[sheet showFromToolbar:toolbar];
	[sheet release];
}

- (IBAction)mapTypeChanged {
	switch (mapTypeControl.selectedSegmentIndex) {
		case 0:
			mapView.mapType = MKMapTypeStandard;
			break;
		case 1:
			mapView.mapType = MKMapTypeHybrid;
			break;
		case 2:
			mapView.mapType = MKMapTypeSatellite;
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kUIAlertViewCurrentLocation:
            [self currentLocationAlertViewClickedButtonAtIndex:buttonIndex];
            break;
        case kUIAlertViewPreviousLocation:
            [self previousLocationAlertViewClickedButtonAtIndex:buttonIndex];
            break;
        case kUIAlertViewNoLocation:
            [self noLocationAlertViewClickedButtonAtIndex:buttonIndex];
            break;
        default:
            [NSException raise:@"Unknown AlertView" format:@"Unknown AlertView called delegate"];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:adjustPinActionSheetOriginalLocationTitle]) {
        self.photoUpload.coordinate = self.photoUpload.location.coordinate;
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.photoUpload.coordinate, 500, 500) animated:YES];
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetCurrentLocationTitle]) {
        self.photoUpload.coordinate = self.currentLocation.coordinate;
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.photoUpload.coordinate, 500, 500) animated:YES];
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetPreviousLocationTitle]) {
        self.photoUpload.coordinate = self.previousLocation.coordinate;
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.photoUpload.coordinate, 500, 500) animated:YES];
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetAddTitle]) {
        self.photoUpload.coordinate = [self.mapView centerCoordinate];
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.photoUpload.coordinate, 500, 500) animated:YES];
        [self.mapView addAnnotation:self.photoUpload];
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetRemoveTitle]) {
        [self.mapView removeAnnotation:self.photoUpload];
        self.photoUpload.coordinate = kCLLocationCoordinate2DInvalid;
        
    } 
}

- (void)currentLocationAlertViewClickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            self.photoUpload.coordinate = self.currentLocation.coordinate;
            [self.mapView addAnnotation:self.photoUpload];
            break;
        case 1:
            break;
        default:
            break;
    }
}

- (void)previousLocationAlertViewClickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            self.photoUpload.coordinate = self.previousLocation.coordinate;
            [self.mapView addAnnotation:self.photoUpload];
            break;
        case 1:
            break;
        default:
            break;
    }
}

- (void)noLocationAlertViewClickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            break;
        default:
            break;
    }
}

- (void)dealloc {
	[locationManager stopUpdatingLocation];
	locationManager.delegate = nil;
	[locationManager release];
	[currentLocation release];
    [previousLocation release];
	mapView.delegate = nil;
	[photoUpload release];
    [super dealloc];
}


@end
