#import <UIKit/UIKit.h>
#import "Core/GPSManager.h"

%ctor {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[GPSManager sharedManager] setup];
        });
    }
}
