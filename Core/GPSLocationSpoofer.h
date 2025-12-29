#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GPSLocationSpoofer : NSObject

+ (instancetype)shared;

/* تفعيل التزييف بموقع محدد */
- (void)enableWithLocation:(CLLocation *)location;

/* إيقاف التزييف */
- (void)disable;

/* هل التزييف مفعّل؟ */
- (BOOL)isEnabled;

/* الموقع المزيف الحالي */
- (CLLocation *)currentFakeLocation;

@end