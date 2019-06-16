#import <Foundation/Foundation.h>
#import "AMBNCallResult.h"

@interface AMBNEnrollVoiceResult : AMBNCallResult

@property(nonatomic, readonly) bool success;
@property(nonatomic, strong, readonly) NSNumber *samplesCount;

- (instancetype)initWithSuccess:(bool)success samplesCount:(NSNumber *)samplesCount metadata:(NSData *)metadata;

@end
