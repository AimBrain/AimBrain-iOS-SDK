#import <Foundation/Foundation.h>
#import "AMBNTextInputCollectorDelegate.h"
#import "AMBNViewIdChainExtractor.h"

@interface AMBNTextInputCollector : NSObject

@property (nonatomic, weak) id delegate;
@property NSData * sensitiveSalt;

-(instancetype)initWithBuffer: (NSMutableArray *) buffer idExtractor: (AMBNViewIdChainExtractor *) idExtractor;

- (void) start;
- (void) stop;
@end
