#import <Foundation/Foundation.h>

@interface GPSManager : NSObject

+ (instancetype)sharedManager;

- (void)setup;
- (void)presentMapInterface;
- (BOOL)isSpoofingEnabled;

@end