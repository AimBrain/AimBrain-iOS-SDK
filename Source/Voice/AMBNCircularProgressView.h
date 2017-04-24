
#import <UIKit/UIKit.h>

@interface AMBNCircularProgressView : UIView

@property(nonatomic, strong) UIColor *trackTintColor;
@property(nonatomic, assign) CGFloat trackStrokeWidth;
@property(nonatomic, strong) UIColor *progressTintColor;
@property(nonatomic, assign) CGFloat progressStrokeWidth;

- (void)setProgress:(CGFloat)progress;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated withDuration:(CFTimeInterval)duration;

- (CGFloat)progress;

@end
