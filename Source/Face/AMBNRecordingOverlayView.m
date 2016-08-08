#import "AMBNRecordingOverlayView.h"

@interface AMBNRecordingOverlayView()
@property (weak, nonatomic) IBOutlet UIView *faceOval;
@end

@implementation AMBNRecordingOverlayView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]));
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextClosePath(context);
    
    CGRect ovalFrame = [self convertRect:[self.faceOval frame] fromView:self.faceOval.superview];
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:ovalFrame cornerRadius:ovalFrame.size.width/2];
    CGContextAddPath(context, [bezierPath bezierPathByReversingPath].CGPath);
    CGContextFillPath(context);
    CGContextRetain(context);
}

@end