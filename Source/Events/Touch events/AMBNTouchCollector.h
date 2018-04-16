#import <Foundation/Foundation.h>
#import "AMBNTouchCollectorDelegate.h"
#import "AMBNViewIdChainExtractor.h"

typedef void(^EventCollectorBlock)(void);

@class AMBNEventBuffer;

@interface AMBNTouchCollector : NSObject

@property (weak, nonatomic) id<AMBNTouchCollectorDelegate> delegate;
@property NSData *sensitiveSalt;

-(instancetype)initWithBuffer:(AMBNEventBuffer *)buffer idExtractor:(AMBNViewIdChainExtractor *)idExtractor eventCollected:(EventCollectorBlock)eventCollectedBlock;

@end
