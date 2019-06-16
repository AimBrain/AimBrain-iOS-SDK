#import "AMBNBehaviouralResult.h"


@interface AMBNBehaviouralResult ()
/*!
 @discussion Score is value between 0 and 1.
 */
@property(nonatomic, strong, readwrite) NSNumber *score;
/*!
 @discussion Behavioral analysis engine learning status.
 */
@property(nonatomic, readwrite) NSInteger status;
/*!
 @discussion Session.
 */
@property(nonatomic, strong, readwrite) NSString *session;
@end

@implementation AMBNBehaviouralResult

- (instancetype)initWithScore:(NSNumber *)score status:(NSInteger)status session:(NSString *)session metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.score = score;
        self.status = status;
        self.session = session;
    }
    return self;
}

@end
