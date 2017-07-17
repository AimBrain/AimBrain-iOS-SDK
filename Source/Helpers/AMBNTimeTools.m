
#import "AMBNTimeTools.h"


@implementation AMBNTimeTools

+ (NSInteger)systemUpTime {
    
    return [[NSProcessInfo processInfo] systemUptime];
}

+ (NSInteger)systemUpTimeInMilliseconds {
    
    return round([self systemUpTime] * 1000);
}

@end
