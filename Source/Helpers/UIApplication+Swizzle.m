
#import "UIApplication+Swizzle.h"
#import <objc/runtime.h>

@interface UIApplication (SwizzlePrivate)
@property (nonatomic, copy) SwizzleCompletion completionHandler;
@end

static void * SwizzleCompletionPropertyKey = &SwizzleCompletionPropertyKey;

@implementation UIApplication (Swizzle)

- (void)swizzle:(SwizzleCompletion)completion {
    self.completionHandler = completion;
    
    Method oldMethod = class_getInstanceMethod([self class], @selector(sendEvent:));
    Method newMethod = class_getInstanceMethod([self class], @selector(interceptAndSendEvent:));
    method_exchangeImplementations(oldMethod, newMethod);
}

- (void)interceptAndSendEvent:(UIEvent *)event {
    if (self.completionHandler) {
        self.completionHandler(self, event);
    }
    [self interceptAndSendEvent:event];
}

#pragma mark - Setter and getter

- (SwizzleCompletion)completionHandler {
    return objc_getAssociatedObject(self, SwizzleCompletionPropertyKey);
}

- (void)setCompletionHandler:(SwizzleCompletion)completionHandler {
    objc_setAssociatedObject(self, SwizzleCompletionPropertyKey, completionHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
