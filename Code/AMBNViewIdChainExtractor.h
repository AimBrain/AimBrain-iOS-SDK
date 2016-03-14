#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AMBNViewIdChainExtractor : NSObject

@property NSMapTable * registeredViews;

-(instancetype) initWithRegisteredViews: (NSMapTable *)registeredViews;
- (NSArray *) identifierChainForView:(UIView *) view;

@end
