#import "AMBNViewIdChainExtractor.h"
#import <UIKit/UIKit.h>

@implementation AMBNViewIdChainExtractor

-(instancetype) initWithRegisteredViews: (NSMapTable *)registeredViews{
    self = [super init];
    self.registeredViews = registeredViews;
    return self;
}

- (NSArray *) identifierChainForView:(UIView *) tView{
    UIView *view = tView;
    NSMutableArray *identifiers = [NSMutableArray array];
    while (view != nil){
        NSString * identifier = [self.registeredViews objectForKey:view];
        if (identifier){
            [identifiers addObject:identifier];
        }
        view = view.superview;
    }
    return identifiers;

}

@end
