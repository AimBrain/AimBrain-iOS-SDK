#import <Foundation/Foundation.h>
#import "AMBNCapturingApplication.h"
#import "AMBNCapturingApplicationDelegate.h"
#import "AMBNTouchCollectorDelegate.h"
#import "AMBNViewIdChainExtractor.h"

@interface AMBNTouchCollector : NSObject <AMBNCapturingApplicationDelegate>

@property (weak, nonatomic) id<AMBNTouchCollectorDelegate> delegate;
@property NSData *sensitiveSalt;

-(instancetype)initWithBuffer: (NSMutableArray *) buffer capturingApplication: (AMBNCapturingApplication *) capturingApplication idExtractor:(AMBNViewIdChainExtractor *) idExtractor;

@end
