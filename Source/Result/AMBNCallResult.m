#import "AMBNCallResult.h"


@interface AMBNCallResult ()

/*!
  @discussion Response metadata
 */
@property(nonatomic, strong, readwrite) NSData *metadata;

@end

@implementation AMBNCallResult

- (NSString *)metadataString {
    if (self.metadata) {
        return [[NSString alloc] initWithData:self.metadata encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (instancetype)init {
    return [self initWithMetadata: nil];
}

- (instancetype)initWithMetadata:(NSData *)metadata {
    self = [super init];
    if (self) {
        self.metadata = metadata;
    }
    return self;
}


@end
