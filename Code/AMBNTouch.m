#import "AMBNTouch.h"

@implementation AMBNTouch

- (instancetype) initWithTouch: (UITouch *) touch touchId: (unsigned int) touchId identifiers: (NSArray *) identifiers{
    self = [super init];
    self.touchId = touchId;
    self.timestamp = round(touch.timestamp * 1000);
    if([touch respondsToSelector:@selector(force)]){
        self.force = [touch force];
    }else{
        self.force = 0;
    }
    if([touch respondsToSelector:@selector(majorRadius)]){
        self.radius = [touch majorRadius];
    }else{
        self.radius = 0;
    }
    self.relativeLocation = [touch locationInView:touch.view];
    self.absoluteLocation = [touch locationInView:nil];
    self.absoluteLocation = [touch locationInView:nil];
    self.phase = [touch phase];
    self.identifiers = identifiers;
    return self;
}


@end
