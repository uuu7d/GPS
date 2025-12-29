#import "GPSFavoritesStore.h"
#import "Models/GPSLocationModel.h"

static NSString *const kGPSStoredLocation = @"gps.fake.location";

@implementation GPSFavoritesStore

+ (instancetype)shared {
    static GPSFavoritesStore *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [GPSFavoritesStore new];
    });
    return s;
}

- (void)saveLocation:(GPSLocationModel *)location {
    NSData *data =
    [NSKeyedArchiver archivedDataWithRootObject:location
                          requiringSecureCoding:YES
                                          error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data
                                              forKey:kGPSStoredLocation];
}

- (GPSLocationModel *)loadLocation {
    NSData *data =
    [[NSUserDefaults standardUserDefaults] objectForKey:kGPSStoredLocation];
    if (!data) return nil;

    return [NSKeyedUnarchiver unarchivedObjectOfClass:GPSLocationModel.class
                                             fromData:data
                                                error:nil];
}

@end
