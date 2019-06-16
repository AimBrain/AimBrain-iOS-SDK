#import "AMBNEnrollFaceResult.h"
#import "AMBNEnrollVoiceResult.h"


@interface AMBNEnrollVoiceResult ()
@property(nonatomic, readwrite) bool success;
@property(nonatomic, strong, readwrite) NSNumber *samplesCount;
@end

@implementation AMBNEnrollVoiceResult

- (instancetype)initWithSuccess:(bool)success samplesCount:(NSNumber *)samplesCount metadata:(NSData *)metadata {
    self = [super initWithMetadata:metadata];
    if (self) {
        self.success = success;
        self.samplesCount = samplesCount;
    }
    return self;
}

@end
