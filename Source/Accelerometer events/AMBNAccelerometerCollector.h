#import <Foundation/Foundation.h>

@interface AMBNAccelerometerCollector : NSObject

@property NSTimeInterval collectionPeriod;
@property NSTimeInterval updateInterval;

- (void) trigger;

- (instancetype)initWithBuffer: (NSMutableArray *) buffer collectionPeriod:(NSTimeInterval) collectionPeriod updateInterval: (NSTimeInterval) updateInterval;

@end
