
#import <UIKit/UIKit.h>

@interface UIApplication (Swizzle)

typedef void(^SwizzleCompletion)(id application, UIEvent *event);

- (void)swizzle:(SwizzleCompletion)completion;

@end
