#import "GPSLocationModel.h"

@implementation GPSLocationModel

+ (BOOL)supportsSecureCoding { return YES; }

- (instancetype)initWithLatitude:(double)lat longitude:(double)lon {
    if (self = [super init]) {
        _latitude = lat;
        _longitude = lon;
    }
    return self;
}

- (CLLocation *)asCLLocation {
    return [[CLLocation alloc] initWithLatitude:self.latitude
                                      longitude:self.longitude];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeDouble:self.latitude forKey:@"lat"];
    [coder encodeDouble:self.longitude forKey:@"lon"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithLatitude:[coder decodeDoubleForKey:@"lat"]
                        longitude:[coder decodeDoubleForKey:@"lon"]];
}

@end