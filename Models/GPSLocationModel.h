#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GPSLocationModel : NSObject <NSSecureCoding>

@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;

- (instancetype)initWithLatitude:(double)lat longitude:(double)lon;
- (CLLocation *)asCLLocation;

@end