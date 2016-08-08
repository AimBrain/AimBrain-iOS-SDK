#import "AMBNCameraOverlay.h"
@import CoreGraphics;

@implementation AMBNCameraOverlay

-(void)layoutSubviews{
    CGFloat previewFullscreenBreakpoint = 480;
    if (self.frame.size.height <= previewFullscreenBreakpoint && self.previewHeightConstraint == nil){
        self.previewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.previewOverlay attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
        [self addConstraint:self.previewHeightConstraint];
    }else if(self.frame.size.height > previewFullscreenBreakpoint && self.previewHeightConstraint){
        [self removeConstraint:self.previewHeightConstraint];
        self.previewHeightConstraint = nil;
    }
        
    [super layoutSubviews];
}
- (void)drawRect:(CGRect)rect
{
    
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

- (IBAction)takePicture:(id)sender {
    [self.delegate takePicturePressedCameraOverlay:self];
}

@end
