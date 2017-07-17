#import "AMBNAccelerometerCollector.h"
#import <CoreMotion/CoreMotion.h>
#import "AMBNAcceleration.h"
#import "AMBNEventBuffer.h"

@interface AMBNAccelerometerCollector ()

@property AMBNEventBuffer *buffer;
@property NSTimer *stopTimer;
@property CMMotionManager *motionManager;
@property (nonatomic, strong) CMAccelerometerHandler accelerometerHandler;
@property NSTimeInterval stopTimestamp;
@property NSOperationQueue *queue;

@end

@implementation AMBNAccelerometerCollector

- (instancetype)initWithBuffer:(AMBNEventBuffer *)buffer collectionPeriod:(NSTimeInterval)collectionPeriod updateInterval:(NSTimeInterval)updateInterval eventCollected:(EventCollectorBlock)eventCollectedBlock {
    self = [self init];
    self.collectionPeriod = collectionPeriod;
    self.buffer = buffer;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = updateInterval;
    self.queue = [[NSOperationQueue alloc] init];
    self.stopTimer = [[NSTimer alloc] init];
    
    __weak AMBNAccelerometerCollector *weakSelf = self;
    self.accelerometerHandler = ^ void (CMAccelerometerData *accelerometerData, NSError *error) {
        if (error == nil && accelerometerData != nil) {
            
            AMBNAcceleration * acc = [AMBNAcceleration accelerationWithAccelerationData:accelerometerData];
            @synchronized(weakSelf.buffer) {
                [weakSelf.buffer addObject:acc];
            }
            if (eventCollectedBlock) {
                eventCollectedBlock();
            }
            
        }
    };
    
    return self;
}

- (void) trigger {
    [self.stopTimer invalidate];
    [self.motionManager startAccelerometerUpdatesToQueue:self.queue withHandler:self.accelerometerHandler];
    
    NSDate * stopDate = [[[NSDate alloc] init] dateByAddingTimeInterval:self.collectionPeriod];
    self.stopTimer = [[NSTimer alloc] initWithFireDate:stopDate interval:0.0 target:self selector:@selector(stopCapturing) userInfo:nil repeats:false];
    [[NSRunLoop currentRunLoop] addTimer:self.stopTimer forMode:NSDefaultRunLoopMode];
}

- (void) stopCapturing {
    [self.motionManager stopAccelerometerUpdates];
}

@end
