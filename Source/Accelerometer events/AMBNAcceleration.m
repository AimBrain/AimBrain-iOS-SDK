#import "AMBNAcceleration.h"

@implementation AMBNAcceleration

+ (instancetype) accelerationWithAccelerationData:(CMAccelerometerData *) data{
    AMBNAcceleration *acceleration = [[self alloc] init];
    acceleration.x = data.acceleration.x;
    acceleration.y = data.acceleration.y;
    acceleration.z = data.acceleration.z;
    acceleration.timestamp = round( data.timestamp * 1000 );
    return acceleration;
}

@end
