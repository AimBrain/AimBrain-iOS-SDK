#import "AMBNSerializedRequest.h"


@interface AMBNSerializedRequest ()
@property (nonatomic, readwrite, strong) NSData *data;
@end

@implementation AMBNSerializedRequest {

}
- (NSString *)dataString {
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        self.data = data;
    }
    return self;
}

@end
