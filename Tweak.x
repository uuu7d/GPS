#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <objc/runtime.h>
#import "GPSAdvancedSettingsViewController.h"
#import "GPSCoordinateUtils.h"
#import "GPSLocationModel.h"
#import "GPSLocationViewModel.h"
#import "GPSRouteManager.h"

// تعريف مفاتيح الإعدادات
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

// إشعارات
NSString *const kLocationSpoofingChangedNotification = @"LocationSpoofingChanged";
NSString *const kAltitudeSpoofingChangedNotification = @"AltitudeSpoofingChanged";
NSString *const kMovingModeChangedNotification = @"MovingModeChanged";
NSString *const kShowGPSSettingsNotification = @"ShowGPSSettings";

// مدير الموقع
@interface GPSLocationManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) BOOL isLocationSpoofingEnabled;
@property (nonatomic, assign) BOOL isAltitudeSpoofingEnabled;
@property (nonatomic, assign) BOOL isMovingModeEnabled;
@property (nonatomic, assign) BOOL isRandomizeEnabled;
@property (nonatomic, assign) BOOL isAutoStepEnabled;

@property (nonatomic, strong) NSMutableArray<CLLocation *> *movingPath;
@property (nonatomic, assign) NSUInteger currentPathIndex;
@property (nonatomic, assign) double movingSpeed;
@property (nonatomic, assign) double autoStepDistance;
@property (nonatomic, assign) double randomizeRadius;

@property (nonatomic, strong) CLLocation *cachedFakeLocation;
@property (nonatomic, strong) NSDate *lastLocationUpdate;

- (void)loadSettings;
- (void)saveSettings;
- (CLLocation *)nextFakeLocation;
- (CLLocation *)createFakeLocationWithLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;
- (CLLocation *)randomLocationAroundCurrentLocation;
- (NSArray<CLLocation *> *)generatePathFromLocation:(CLLocation *)startLoc toLocation:(CLLocation *)endLoc withSteps:(NSUInteger)steps;
- (void)startAutomatedMovement;
- (void)stopAutomatedMovement;
@end

@implementation GPSLocationManager

+ (instancetype)sharedManager {
    static GPSLocationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GPSLocationManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self loadSettings];
        _movingPath = [NSMutableArray array];
        _currentPathIndex = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLocationSpoofingChanged:)
                                                     name:kLocationSpoofingChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isLocationSpoofingEnabled = [defaults boolForKey:kLocationSpoofingEnabledKey];
    _isAltitudeSpoofingEnabled = [defaults boolForKey:kAltitudeSpoofingEnabledKey];
    _isMovingModeEnabled = [defaults boolForKey:kMovingModeEnabledKey];
    _isRandomizeEnabled = [defaults boolForKey:kRandomizeKey];
    _isAutoStepEnabled = [defaults boolForKey:kAutoStepKey];
    
    _movingSpeed = [defaults doubleForKey:kMovingSpeedKey] ?: 5.0;
    _autoStepDistance = [defaults doubleForKey:kAutoStepDistanceKey] ?: 10.0;
    _randomizeRadius = [defaults doubleForKey:kRandomizeRadiusKey] ?: 50.0;
    
    NSArray *pathData = [defaults objectForKey:kMovingPathKey];
    if (pathData && pathData.count > 0) {
        _movingPath = [NSMutableArray array];
        for (NSDictionary *locationDict in pathData) {
            double lat = [locationDict[@"latitude"] doubleValue];
            double lng = [locationDict[@"longitude"] doubleValue];
            double alt = [locationDict[@"altitude"] doubleValue];
            CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lng)
                                                               altitude:alt
                                                     horizontalAccuracy:5.0
                                                       verticalAccuracy:5.0
                                                              timestamp:[NSDate date]];
            [_movingPath addObject:location];
        }
    }
}

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:_isLocationSpoofingEnabled forKey:kLocationSpoofingEnabledKey];
    [defaults setBool:_isAltitudeSpoofingEnabled forKey:kAltitudeSpoofingEnabledKey];
    [defaults setBool:_isMovingModeEnabled forKey:kMovingModeEnabledKey];
    [defaults setBool:_isRandomizeEnabled forKey:kRandomizeKey];
    [defaults setBool:_isAutoStepEnabled forKey:kAutoStepKey];
    
    [defaults setDouble:_movingSpeed forKey:kMovingSpeedKey];
    [defaults setDouble:_autoStepDistance forKey:kAutoStepDistanceKey];
    [defaults setDouble:_randomizeRadius forKey:kRandomizeRadiusKey];
    
    if (_movingPath && _movingPath.count > 0) {
        NSMutableArray *pathData = [NSMutableArray array];
        for (CLLocation *location in _movingPath) {
            [pathData addObject:@{
                @"latitude": @(location.coordinate.latitude),
                @"longitude": @(location.coordinate.longitude),
                @"altitude": @(location.altitude)
            }];
        }
        [defaults setObject:pathData forKey:kMovingPathKey];
    }
    
    [defaults synchronize];
}

// بقية وظائف GPSLocationManager تبقى كما هي مع التركيز على الرسائل بالعربية فقط
@end

// SpringBoard Hook
%hook SpringBoard

%new
- (void)showGPSQuickOptions {
    NSLog(@"[GPS++] عرض خيارات GPS");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowGPSSettingsNotification object:nil];
    });
}

%end

// CLLocationManager Hook
%hook CLLocationManager

%new
- (void)sendFakeLocationUpdate {
    GPSLocationViewModel *viewModel = [GPSLocationViewModel sharedInstance];
    if (viewModel.isLocationSpoofingEnabled) {
        CLLocationCoordinate2D coordinate = viewModel.currentLocation.coordinate;
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            double accuracy = viewModel.currentLocation.accuracy > 0 ? viewModel.currentLocation.accuracy : 5.0;
            double altitude = viewModel.currentLocation.altitude;
            double speed = viewModel.currentLocation.speed;
            double course = viewModel.currentLocation.course;
            NSDate *timestamp = [NSDate date];
            CLLocation *fakeLocation = [[CLLocation alloc] 
                                        initWithCoordinate:coordinate
                                        altitude:altitude
                                        horizontalAccuracy:accuracy
                                        verticalAccuracy:accuracy
                                        course:course
                                        speed:speed
                                        timestamp:timestamp];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate locationManager:self didUpdateLocations:@[fakeLocation]];
                });
            }
        }
    }
}

%end

// GPSTriggerManager
@implementation GPSTriggerManager

- (void)showGPSInterface {
    dispatch_async(dispatch_get_main_queue(), ^{
        MapViewController *mapVC = [[MapViewController alloc] init];
        // فرض RTL
        if (@available(iOS 9.0, *)) {
            mapVC.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        }
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mapVC];
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIViewController *rootVC = keyWindow.rootViewController;
        UIViewController *topVC = [self topViewControllerWithRootViewController:rootVC];
        
        if (topVC) {
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            [topVC presentViewController:navController animated:YES completion:nil];
        }
    });
}

- (void)showToastWithMessage:(NSString *)message {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *toastView = [[UIView alloc] init];
    toastView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    toastView.layer.cornerRadius = 10;
    toastView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = message;  // يجب تمرير رسالة عربية فقط
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentRight;
    label.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [toastView addSubview:label];
    [window addSubview:toastView];
    
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:toastView.leadingAnchor constant:15],
        [label.trailingAnchor constraintEqualToAnchor:toastView.trailingAnchor constant:-15],
        [label.topAnchor constraintEqualToAnchor:toastView.topAnchor constant:10],
        [label.bottomAnchor constraintEqualToAnchor:toastView.bottomAnchor constant:-10],
        [toastView.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [toastView.bottomAnchor constraintEqualToAnchor:window.bottomAnchor constant:-100]
    ]];
    
    toastView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        toastView.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                toastView.alpha = 0;
            } completion:^(BOOL finished) {
                [toastView removeFromSuperview];
            }];
        });
    }];
}

@end

// في أي مكان يوجد UIAlertController أو رسائل للمستخدم يجب التأكد أنها عربية:
// مثال:
UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GPS++"
                                                               message:@"يرجى استخدام إعدادات التطبيق لفتح GPS"
                                                        preferredStyle:UIAlertControllerStyleAlert];
[alert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
