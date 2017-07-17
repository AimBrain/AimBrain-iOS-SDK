#import "AMBNCapturingApplication.h"

@implementation AMBNCapturingApplication
{

}

-(void)sendEvent:(UIEvent *)event {
    if ([self keyWindow] == nil){
        NSLog(@"keyWindow is nil!");
        [super sendEvent:event];
        return;
    }
    [self.capturingDelegate capturingApplication: self event: event];
    [super sendEvent:event];
}




@end
