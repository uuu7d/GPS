#import "GPSManager.h"
#import <UIKit/UIKit.h>

@interface GPSManager ()
@property (nonatomic, assign) BOOL spoofingEnabled;
@end

@implementation GPSManager

+ (instancetype)sharedManager {
    static GPSManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[GPSManager alloc] init];
    });
    return shared;
}

- (void)setup {
    self.spoofingEnabled = NO;
    [self registerGesture];
}

- (BOOL)isSpoofingEnabled {
    return self.spoofingEnabled;
}

#pragma mark - Window Helper (iOS 13+ / iOS 18)

- (UIWindow *)activeKeyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) {
            continue;
        }

        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

#pragma mark - Gesture

- (void)registerGesture {
    UIWindow *window = [self activeKeyWindow];
    if (!window) return;

    UILongPressGestureRecognizer *gesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleGesture:)];

    gesture.minimumPressDuration = 5.0;
    gesture.numberOfTouchesRequired = 2;

    [window addGestureRecognizer:gesture];
}

- (void)handleGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self presentMapInterface];
    }
}

#pragma mark - UI

- (void)presentMapInterface {
    // سنربط الواجهة هنا لاحقًا
    NSLog(@"[GPSInjector] Map interface requested");
}

@end
