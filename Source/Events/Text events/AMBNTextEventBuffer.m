
#import "AMBNTextEventBuffer.h"
#import "AMBNTextEvent.h"


@implementation AMBNTextEventBuffer

- (NSInteger)sizeOfEventsInRange:(NSRange)range {
    
    NSArray *subarray = [self.buffer subarrayWithRange:range];
    NSInteger size = subarray.count * self.eventSizeInBytes;
    for (AMBNTextEvent *event in subarray) {
        size += [event.text lengthOfBytesUsingEncoding:kCFStringEncodingUTF8];
    }
    return size;
}

@end
