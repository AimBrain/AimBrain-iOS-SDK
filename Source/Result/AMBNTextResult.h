#import <Foundation/Foundation.h>
#import "AMBNCallResult.h"

@interface AMBNTextResult : AMBNCallResult

@property(nonatomic, readonly) NSString *tokenText;

- (instancetype)initWithTokenText:(NSString *)text metadata:(NSData *)metadata;

@end

