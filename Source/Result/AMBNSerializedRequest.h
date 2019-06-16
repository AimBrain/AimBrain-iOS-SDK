#import <Foundation/Foundation.h>


@interface AMBNSerializedRequest : NSObject
@property (nonatomic, readonly, strong) NSData *data;
@property (nonatomic, readonly, strong) NSString *dataString;

- (instancetype)initWithData:(NSData *)data;
@end
