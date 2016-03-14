#import "AMBNBehaviouralJSONComposer.h"
#import "AMBNTouch.h"
#import "AMBNAcceleration.h"
#import "AMBNTextEvent.h"

@implementation AMBNBehaviouralJSONComposer

- (id) composeWithTouches: (NSArray *) touches accelerations: (NSArray *) accelerations textEvents: (NSArray *) textEvents session: (NSString *) session{
    NSDictionary * json = @{
                            @"session" : session,
                            @"touches" : [self composeTouchesJSON:touches],
                            @"accelerations" : [self composeAccelerationsJSON:accelerations],
                            @"textEvents" : [self composeTextEventsJSON:textEvents],
                            };
    return json;
    
}

- (NSArray *) composeTouchesJSON: (NSArray *) touches{
    NSMutableArray *touchesJSON = [NSMutableArray array];

    for(AMBNTouch * touch in touches){
        [touchesJSON addObject:@{
                                 @"tid" : [NSNumber numberWithInt:touch.touchId],
                                 @"t" : [NSNumber numberWithInt:touch.timestamp],
                                 @"r" : [NSNumber numberWithFloat:touch.radius],
                                 @"x" : [NSNumber numberWithFloat:touch.absoluteLocation.x],
                                 @"y" : [NSNumber numberWithFloat:touch.absoluteLocation.y],
                                 @"rx" : [NSNumber numberWithFloat:touch.relativeLocation.x],
                                 @"ry" : [NSNumber numberWithFloat:touch.relativeLocation.y],
                                 @"f" : [NSNumber numberWithFloat:touch.force],
                                 @"p" : [NSNumber numberWithInt:touch.phase],
                                 @"ids" : touch.identifiers
                                 }];
    }
    return [NSArray arrayWithArray:touchesJSON];
}

- (NSArray *) composeAccelerationsJSON: (NSArray *) accelerations{
    NSMutableArray *accelerationsJSON = [NSMutableArray array];
    for(AMBNAcceleration * acc in accelerations){
        [accelerationsJSON addObject:@{
                                 @"t" : [NSNumber numberWithInt:acc.timestamp],
                                 @"x" : [NSNumber numberWithFloat:acc.x],
                                 @"y" : [NSNumber numberWithFloat:acc.y],
                                 @"z" : [NSNumber numberWithFloat:acc.z],
                                 }];
    }
    return [NSArray arrayWithArray:accelerationsJSON];
}

- (NSArray *) composeTextEventsJSON: (NSArray *) textEvents{
    NSMutableArray *textEventsJSON = [NSMutableArray array];
    for(AMBNTextEvent * textEvent in textEvents){
        [textEventsJSON addObject:@{
                                       @"t" : [NSNumber numberWithInt:textEvent.timestamp],
                                       @"tx" : textEvent.text,
                                       @"ids": textEvent.identifiers
                                       }];
    }
    return [NSArray arrayWithArray:textEventsJSON];
}
@end
