#import "AMBNCompareFaceResult.h"


@interface AMBNCompareFaceResult ()
@property(nonatomic, strong, readwrite) NSNumber *score;
@property(nonatomic, strong, readwrite) NSNumber *firstLiveliness;
@property(nonatomic, strong, readwrite) NSNumber *secondLiveliness;
@end

@implementation AMBNCompareFaceResult

- (instancetype)initWithSimilarity:(NSNumber *)score firstLiveliness:(NSNumber *)firstLiveliness secondLiveliness:(NSNumber *)secondLiveliness metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.score = score;
        self.firstLiveliness = firstLiveliness;
        self.secondLiveliness = secondLiveliness;
    }
    return self;
}

@end
