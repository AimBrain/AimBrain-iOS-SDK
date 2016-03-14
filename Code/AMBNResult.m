#import "AMBNResult.h"


@implementation AMBNResult

- (instancetype) initWithScore: (NSNumber *) score status: (NSInteger) status session: (NSString *) session {
    self = [super init];
    self.score = score;
    self.status = status;
    self.session = session;
    return self;
}

@end
