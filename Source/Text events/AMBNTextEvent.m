#import "AMBNTextEvent.h"

@implementation AMBNTextEvent

-(instancetype) initWithText: (NSString*) text timestamp: (int) timestamp identifiers:(NSArray *)identifiers{
    self = [super init];
    self.text = text;
    self.timestamp = timestamp;
    self.identifiers = identifiers;
    return self;
}

@end
