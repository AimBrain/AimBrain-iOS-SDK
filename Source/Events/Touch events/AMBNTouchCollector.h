#import <Foundation/Foundation.h>
#import "AMBNCapturingApplication.h"
#import "AMBNCapturingApplicationDelegate.h"
#import "AMBNTouchCollectorDelegate.h"
#import "AMBNViewIdChainExtractor.h"

typedef void(^EventCollectorBlock)(void);

@class AMBNEventBuffer;

@interface AMBNTouchCollector : NSObject <AMBNCapturingApplicationDelegate>

@property (weak, nonatomic) id<AMBNTouchCollectorDelegate> delegate;
@property NSData *sensitiveSalt;

-(instancetype)initWithBuffer:(AMBNEventBuffer *)buffer capturingApplication:(AMBNCapturingApplication *)capturingApplication idExtractor:(AMBNViewIdChainExtractor *)idExtractor eventCollected:(EventCollectorBlock)eventCollectedBlock;

@end
