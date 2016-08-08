#import "AMBNPrivacyGuard.h"

@implementation AMBNPrivacyGuard

-(instancetype)initWithViews:(NSArray *) views {
    self = [super init];
    self.allViews = false;
    self.views = views;
    _valid = true;
    return self;
}

-(instancetype)initWithAllViews{
    self = [super init];
    self.allViews = true;
    _valid = true;
    return self;
}

-(void)invalidate{
    _valid = false;
}

-(BOOL)isViewIgnored:(UIView *) view {
    if(!self.valid){
        return false;
    }
    
    if(self.allViews){
        return true;
    }
    
    for(UIView * guardedView in self.views){
        if([view isDescendantOfView:guardedView]){
            return true;
        }
    }
    
    return false;
}
@end
