#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <objc/runtime.h>

#import "MapViewController.h"
#import "GPSAdvancedSettingsViewController.h"
#import "GPSCoordinateUtils.h"
#import "GPSLocationModel.h"
#import "GPSLocationViewModel.h"
#import "GPSRouteManager.h"

#pragma mark - تعريف مفاتيح الإعدادات

#define kUserDefaultsDomain                @"com.gps.locationspoofer"
#define kLocationSpoofingEnabledKey        @"LocationSpoofingEnabled"
#define kAltitudeSpoofingEnabledKey        @"AltitudeSpoofingEnabled"
#define kLatitudeKey                       @"latitude"
#define kLongitudeKey                      @"longitude"
#define kAltitudeKey                       @"altitude"
#define kSpeedKey                          @"speed"
#define kCourseKey                         @"course"
#define kAccuracyKey                       @"accuracy"
#define kLocationHistoryKey                @"LocationHistory"
#define kPresetLocationsKey                @"PresetLocations"
#define kMovingModeEnabledKey              @"MovingModeEnabled"
#define kMovingPathKey                     @"MovingPath"
#define kMovingSpeedKey                    @"MovingSpeed"
#define kRandomizeKey                      @"RandomizeEnabled"
#define kRandomizeRadiusKey                @"RandomizeRadius"
#define kAutoStepKey                       @"AutoStepEnabled"
#define kAutoStepDistanceKey               @"AutoStepDistance"

#pragma mark - الإشعارات

NSString *const kLocationSpoofingChangedNotification = @"LocationSpoofingChanged";
NSString *const kAltitudeSpoofingChangedNotification = @"AltitudeSpoofingChanged";
NSString *const kMovingModeChangedNotification      = @"MovingModeChanged";
NSString *const kShowGPSSettingsNotification        = @"ShowGPSSettings";

#pragma mark - GPSLocationManager

@interface GPSLocationManager : NSObject
+ (instancetype)sharedManager;
@property (nonatomic, assign) BOOL isLocationSpoofingEnabled;
@end

@implementation GPSLocationManager

+ (instancetype)sharedManager {
    static GPSLocationManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

@end

#pragma mark - Hook SpringBoard

%hook SpringBoard

%new
- (void)showGPSQuickOptions {
    NSLog(@"[GPS++] تم طلب عرض واجهة إعدادات GPS");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:kShowGPSSettingsNotification
            object:nil];
    });
}

%end

#pragma mark - Hook CLLocationManager

%hook CLLocationManager

%new
- (void)sendFakeLocationUpdate {
    GPSLocationViewModel *viewModel = [GPSLocationViewModel sharedInstance];
    if (!viewModel.isLocationSpoofingEnabled) return;

    CLLocation *current = viewModel.currentLocation;
    if (!current) return;

    CLLocation *fakeLocation =
    [[CLLocation alloc] initWithCoordinate:current.coordinate
                               altitude:current.altitude
                     horizontalAccuracy:current.horizontalAccuracy ?: 5.0
                       verticalAccuracy:current.verticalAccuracy ?: 5.0
                                 course:current.course
                                  speed:current.speed
                              timestamp:[NSDate date]];

    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate locationManager:self didUpdateLocations:@[fakeLocation]];
        });
    }
}

%end

#pragma mark - GPSTriggerManager (مصحح بالكامل)

@interface GPSTriggerManager : NSObject
@end

@implementation GPSTriggerManager

#pragma mark أداة تحديد أعلى ViewController (كانت سبب الخطأ)

- (UIViewController *)topViewControllerWithRootViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController) {
        return [self topViewControllerWithRootViewController:rootViewController.presentedViewController];
    }
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootViewController;
        return [self topViewControllerWithRootViewController:nav.topViewController];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)rootViewController;
        return [self topViewControllerWithRootViewController:tab.selectedViewController];
    }
    return rootViewController;
}

#pragma mark عرض واجهة GPS

- (void)showGPSInterface {
    dispatch_async(dispatch_get_main_queue(), ^{

        MapViewController *mapVC = [[MapViewController alloc] init];

        // فرض العربية و RTL
        mapVC.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;

        UINavigationController *nav =
        [[UINavigationController alloc] initWithRootViewController:mapVC];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;

        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIViewController *rootVC = window.rootViewController;
        UIViewController *topVC  = [self topViewControllerWithRootViewController:rootVC];

        if (topVC) {
            [topVC presentViewController:nav animated:YES completion:nil];
        }
    });
}

#pragma mark Toast عربي

- (void)showToastWithMessage:(NSString *)message {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;

    UIView *toast = [[UIView alloc] init];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    toast.layer.cornerRadius = 10;
    toast.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.textAlignment = NSTextAlignmentRight;
    label.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    [toast addSubview:label];
    [window addSubview:toast];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:16],
        [label.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-16],
        [label.topAnchor constraintEqualToAnchor:toast.topAnchor constant:10],
        [label.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-10],
        [toast.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:window.bottomAnchor constant:-120]
    ]];

    toast.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

#pragma mark تنبيه عربي (كان سبب خطأ البناء)

- (void)showGPSDisabledAlert {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"GPS++"
                                        message:@"يرجى تفعيل الموقع من إعدادات التطبيق"
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
     [UIAlertAction actionWithTitle:@"حسناً"
                              style:UIAlertActionStyleDefault
                            handler:nil]];

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *topVC =
    [self topViewControllerWithRootViewController:window.rootViewController];

    if (topVC) {
        [topVC presentViewController:alert animated:YES completion:nil];
    }
}

@end
