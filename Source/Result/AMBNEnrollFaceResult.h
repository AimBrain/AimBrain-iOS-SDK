#import <Foundation/Foundation.h>
#import "AMBNCallResult.h"

@interface AMBNEnrollFaceResult : AMBNCallResult

@property(nonatomic, readonly) bool success;
@property(nonatomic, strong, readonly) NSNumber *imagesCount;

- (instancetype)initWithSuccess:(bool)success imagesCount:(NSNumber *)imagesCount metadata:(NSData *)metadata;

@end
