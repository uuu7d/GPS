#import <Foundation/Foundation.h>
@class GPSLocationModel;

@interface GPSFavoritesStore : NSObject

+ (instancetype)shared;
- (void)saveLocation:(GPSLocationModel *)location;
- (GPSLocationModel *)loadLocation;

@end