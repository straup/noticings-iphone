//
//  StreamPhoto.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhoto.h"

#import "APIKeys.h"
#import "NSString+HTML.h"

@implementation StreamPhoto

@synthesize details;

- (id)initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.details = dict;
    }
    return self;
}

-(NSString*)description;
{
    // this is the objective C introspection / toString() method
    return [NSString stringWithFormat:@"<StreamPhoto \"%@\" by %@>", self.title, self.ownername];
}

#pragma mark accessors / view utilities

- (NSString*)flickrId;
{
    return [self.details valueForKeyPath:@"id"];
}

- (NSString*)title;
{
    NSString *title = [[self.details valueForKeyPath:@"title"] stringByRemovingNewLinesAndWhitespace];
    if (title.length > 0) {
        return title;
    }
    return @"Untitled";
}

-(BOOL)hasTitle;
{
    NSString *title = [[self.details valueForKeyPath:@"title"] stringByRemovingNewLinesAndWhitespace];
    return (title.length > 0);
}

- (NSString*)html;
{
    NSString *raw = [self.details valueForKeyPath:@"description._content"];
    return [raw stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
}

- (NSString*)ownername;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (NSString*)ownerId;
{
    return [self.details valueForKeyPath:@"owner"];
}

-(float)latitude;
{
    return [[self.details valueForKey:@"latitude"] floatValue];
}

-(float)longitude;
{
    return [[self.details valueForKey:@"longitude"] floatValue];
}

-(BOOL)hasLocation;
{
    float lat = [[self.details valueForKey:@"latitude"] floatValue];
    float lng = [[self.details valueForKey:@"longitude"] floatValue];
    return (lat != 0 && lng != 0);
}

- (NSString*)placename;
{
    return [NSString stringWithFormat:@"%.3f,%.3f", self.latitude, self.longitude];
}

- (NSString*)woeid;
{
    return [self.details valueForKey:@"woeid"];
}

- (NSURL*) mapPageURL;
{
    NSString *title = [self.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (title.length == 0) {
        title = @"Photo"; // google maps needs something
    }
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%f,%f+(%@)", self.latitude, self.longitude, title];
    return [NSURL URLWithString:mapURL];
}

-(NSURL*)mapImageURL;
{
    int scale = [UIScreen mainScreen].scale; //  1 or 2
    NSString *mapURL = [NSString stringWithFormat:@"cache://maps.googleapis.com/maps/api/staticmap?sensor=false&size=320x70&center=%f,%f&zoom=12&scale=%d&markers=size:small%%7C%f,%f",
                        self.latitude, self.longitude, scale, self.latitude, self.longitude];
    return [NSURL URLWithString:mapURL];
}

- (NSURL*) imageURL;
{
    return [NSURL URLWithString:[[self.details objectForKey:@"url_m"] stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@"cache"]];
}

- (NSURL*) bigImageURL;
{
    NSString *big = [self.details objectForKey:@"url_b"];
    if (!big) {
        big = [self.details objectForKey:@"url_m"];
    }
    return [NSURL URLWithString:[big stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@"cache"]];
}

- (NSURL*) originalImageURL;
{
    if ([self.details valueForKey:@"url_o"]) {
        return [NSURL URLWithString:[[self.details valueForKey:@"url_o"] stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@"cache"]];
    } else {
        return self.bigImageURL;
    }
}

- (NSURL*) avatarURL;
{
    NSString *avatarUrl;
    if ([self.details objectForKey:@"iconserver"] && ![[self.details objectForKey:@"iconserver"] isEqual:@"0"]) {
        avatarUrl = [NSString stringWithFormat:@"cache://farm%@.static.flickr.com/%@/buddyicons/%@.jpg",
                     [self.details objectForKey:@"iconfarm"],
                     [self.details objectForKey:@"iconserver"],
                     [self.details objectForKey:@"owner"]
                     ];
        
    } else {
        avatarUrl = @"cache://www.flickr.com/images/buddyicon.jpg";
    }
    return [NSURL URLWithString:avatarUrl];
}

- (NSURL*) pageURL;
{
    NSString *urlString = [NSString stringWithFormat:@"http://www.flickr.com/photos/%@/%@",
                           [self.details objectForKey:@"pathalias"],
                           [self.details objectForKey:@"id"]
                           ];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)mobilePageURL;
{
    NSString *urlString = [NSString stringWithFormat:@"http://m.flickr.com/photos/%@/%@",
                           [self.details objectForKey:@"pathalias"],
                           [self.details objectForKey:@"id"]
                           ];
    return [NSURL URLWithString:urlString];
}

- (NSString*)dateupload;
{
    return [self.details objectForKey:@"dateupload"];
}

- (NSString*) ago;
{
    NSTimeInterval epoch = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970; // yeah.
    NSString *uploaded = [self.details objectForKey:@"dateupload"];
    if (!uploaded) {
        return @"";
    }
    int ago = epoch - [uploaded doubleValue]; // woooo overflow bug. I hope your friends upload at least once every 2*32 seconds!
    

    if (ago < 0) {
        return @"now"; // clock drift for new uploads can make this -ve
    }

    int seconds = ago % 60;
    int minutes = (ago / 60) % 60;
    int hours = (ago / (60*60)) % 24;
    int days = (ago / (24*60*60));
    
    if (days > 1) {
        return [NSString stringWithFormat:@"%dd", days];
    }
    if (hours > 1) {
        return [NSString stringWithFormat:@"%dh", hours + days*24];
    }
    if (minutes > 1) {
        return [NSString stringWithFormat:@"%dm", minutes + hours*60];
    }
    return [NSString stringWithFormat:@"%ds", seconds + minutes*60];
}

-(int)visibility;
{
    if ([[self.details objectForKey:@"ispublic"] intValue]) {
        return StreamPhotoVisibilityPublic;
    }
    if ([[self.details objectForKey:@"isfriend"] intValue] || [[self.details objectForKey:@"isfamily"] intValue]) {
        return StreamPhotoVisibilityLimited;
    }
    return StreamPhotoVisibilityPrivate;
}

-(NSArray*)tags;
{
    NSString *tags = [self.details valueForKey:@"tags"];
    if (tags.length > 0) {
        return [tags componentsSeparatedByString:@" "];
    }
    return [NSArray array];
}

-(NSArray*)humanTags;
{
    NSPredicate *human = [NSPredicate predicateWithBlock:^(id tag, NSDictionary *bindings) {
        NSRange range = [((NSString*)tag) rangeOfString:@":"];
        if (range.length > 0) {
            return NO;
        }
        return YES;
    }];
    return [self.tags filteredArrayUsingPredicate:human];
}



-(CGFloat)imageHeightForWidth:(CGFloat)width;
{
    float width_m = [[self.details objectForKey:@"width_m"] floatValue];
    float height_m = [[self.details objectForKey:@"height_m"] floatValue];
    CGFloat height = width * height_m / width_m;
    return height;
}


#pragma mark MKAnnotation

-(CLLocationCoordinate2D)coordinate;
{
    CLLocationCoordinate2D location;
    location.latitude = self.latitude;
    location.longitude = self.longitude;
    return location;
}

- (NSString*)subtitle;
{
    return self.ownername;
}




#pragma mark serialize / deserizlise

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.details forKey:@"details"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.details = [coder decodeObjectForKey:@"details"];
    }
    return self;
}


#pragma mark memory managment

- (void)dealloc
{
    [super dealloc];
}

@end
