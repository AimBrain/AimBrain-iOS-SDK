#import <Foundation/Foundation.h>

@class AMBNEventBuffer;

typedef void(^EventCollectorBlock)(void);

@interface AMBNAccelerometerCollector : NSObject

@property NSTimeInterval collectionPeriod;
@property NSTimeInterval updateInterval;

- (void) trigger;

- (instancetype)initWithBuffer:(AMBNEventBuffer *)buffer collectionPeriod:(NSTimeInterval)collectionPeriod updateInterval:(NSTimeInterval)updateInterval eventCollected:(EventCollectorBlock)eventCollectedBlock;

@end
