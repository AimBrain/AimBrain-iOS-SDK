#import "AMBNEnrollFaceResult.h"


@interface AMBNEnrollFaceResult ()
@property(nonatomic, readwrite) bool success;
@property(nonatomic, strong, readwrite) NSNumber *imagesCount;
@end

@implementation AMBNEnrollFaceResult

- (instancetype)initWithSuccess:(bool)success imagesCount:(NSNumber *)imagesCount metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.success = success;
        self.imagesCount = imagesCount;
    }
    return self;
}

@end
