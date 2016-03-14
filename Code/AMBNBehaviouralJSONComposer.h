#import <Foundation/Foundation.h>

@interface AMBNBehaviouralJSONComposer : NSObject

- (id) composeWithTouches: (NSArray *) touches accelerations: (NSArray *) accelerations textEvents: (NSArray *) textEvents session: (NSString *) session;
    
@end
