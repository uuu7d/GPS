#import "GPSLocationSpoofer.h"
#import <objc/runtime.h>

static CLLocation *_fakeLocation = nil;
static BOOL _spoofingEnabled = NO;

@implementation GPSLocationSpoofer

+ (instancetype)shared {
    static GPSLocationSpoofer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GPSLocationSpoofer alloc] init];
    });
    return instance;
}

- (void)enableWithLocation:(CLLocation *)location {
    _fakeLocation = location;
    _spoofingEnabled = YES;
}

- (void)disable {
    _spoofingEnabled = NO;
}

- (BOOL)isEnabled {
    return _spoofingEnabled;
}

- (CLLocation *)currentFakeLocation {
    return _fakeLocation;
}

@end

#pragma mark - CLLocationManager Hook

@implementation CLLocationManager (GPSInjector)

/*
 هذا الـ hook هو قلب التزييف:
 أي تطبيق يطلب location → يحصل على موقعك المزيف
 بدون أن يشعر بشيء
*/

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original =
        class_getInstanceMethod(self, @selector(location));

        Method replaced =
        class_getInstanceMethod(self, @selector(gps_injected_location));

        method_exchangeImplementations(original, replaced);
    });
}

- (CLLocation *)gps_injected_location {
    if ([[GPSLocationSpoofer shared] isEnabled]) {
        CLLocation *fake = [[GPSLocationSpoofer shared] currentFakeLocation];
        if (fake) {
            return fake;
        }
    }

    // استدعاء التنفيذ الأصلي (بعد التبديل)
    return [self gps_injected_location];
}

@end