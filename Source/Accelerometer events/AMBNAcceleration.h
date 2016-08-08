#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

@interface AMBNAcceleration : NSObject

@property CGFloat x;
@property CGFloat y;
@property CGFloat z;
@property int timestamp;

+ (instancetype) accelerationWithAccelerationData:(CMAccelerometerData *) data;

@end
