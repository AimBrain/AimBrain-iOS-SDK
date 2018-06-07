
/*
 * Round button with waving (pulse) animation
 */

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface AMBNCircleButton : UIButton {
    
    UIColor *_originalBackgroundColor;
}

@property IBInspectable UIColor *wavingBackgroundColor;

@property (nonatomic, assign, setter=setAnimating:) BOOL animating;

@end
