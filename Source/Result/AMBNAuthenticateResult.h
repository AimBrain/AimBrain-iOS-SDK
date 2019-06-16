#import <Foundation/Foundation.h>
#import "AMBNCallResult.h"


@interface AMBNAuthenticateResult : AMBNCallResult

@property(nonatomic, strong, readonly) NSNumber *score;

@property(nonatomic, strong, readonly) NSNumber *liveliness;

- (instancetype)initWithScore:(NSNumber *)score liveliness:(NSNumber *)liveliness metadata:(NSData *)metadata;

@end
