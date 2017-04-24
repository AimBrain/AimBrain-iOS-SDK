#import "AMBNCircularProgressView.h"


@interface AMBNCircularProgressView () {
    
    CAShapeLayer *_circlePathLayer;
    CAShapeLayer *_circleTrackLayer;
}

@end


const CFTimeInterval kDefaultProgressDuration = 1;


@implementation AMBNCircularProgressView


- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configure];
    }
    
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    [_circleTrackLayer setFrame:[self bounds]];
    [_circleTrackLayer setPath:[[self circlePath] CGPath]];
    
    [_circlePathLayer setFrame:[self bounds]];
    [_circlePathLayer setPath:[[self circlePath] CGPath]];
}

#pragma mark - Configuration

- (void)configure {
    
    _circleTrackLayer = [[CAShapeLayer alloc] init];
    [_circleTrackLayer setFrame:[self bounds]];
    [_circleTrackLayer setLineWidth:1.0];
    [_circleTrackLayer setFillColor:[[UIColor clearColor] CGColor]];
    [_circleTrackLayer setStrokeColor:[[UIColor blackColor] CGColor]];
    [_circleTrackLayer setStrokeEnd:1.0f];
    
    _circlePathLayer = [[CAShapeLayer alloc] init];
    [_circlePathLayer setFrame:[self bounds]];
    [_circlePathLayer setLineWidth:2.0];
    [_circlePathLayer setFillColor:[[UIColor clearColor] CGColor]];
    [_circlePathLayer setStrokeColor:[[UIColor blackColor] CGColor]];
    
    [[self layer] addSublayer:_circleTrackLayer];
    [[self layer] addSublayer:_circlePathLayer];
    
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setProgress:0];
}

- (UIBezierPath *)circlePath {

    CGRect bounds = [self bounds];
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGFloat radius = MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds)) / 2.0f;
    CGFloat startAngle = (CGFloat) (M_PI_2 * 3.0);
    CGFloat endAngle = (CGFloat) (M_PI_2 * 3.0 + M_PI * 2.0);
    return [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
}

#pragma mark - Public

- (void)setProgress:(CGFloat)progress {
    
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    
    [self setProgress:progress animated:animated withDuration:kDefaultProgressDuration];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated withDuration:(CFTimeInterval)duration {
    
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear]];
    
    if (animated) {
        [CATransaction setAnimationDuration:duration];
    } else {
        [CATransaction setAnimationDuration:0];
    }
    
    if (progress > 1) {
        _circlePathLayer.strokeEnd = 1;
    } else if (progress < 0) {
        _circlePathLayer.strokeEnd = 0;
    } else {
        _circlePathLayer.strokeEnd = progress;
    }
    
    [CATransaction commit];
}

- (CGFloat)progress {
    
    return _circlePathLayer.strokeEnd;
}

#pragma mark - Setters

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    
    _trackTintColor = trackTintColor;
    [_circleTrackLayer setStrokeColor:_trackTintColor.CGColor];
}

- (void)setTrackStrokeWidth:(CGFloat)trackStrokeWidth {
    
    _trackStrokeWidth = trackStrokeWidth;
    [_circleTrackLayer setLineWidth:_trackStrokeWidth];
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
    
    _progressTintColor = progressTintColor;
    [_circlePathLayer setStrokeColor:_progressTintColor.CGColor];
}

- (void)setProgressStrokeWidth:(CGFloat)progressStrokeWidth {
    
    _progressStrokeWidth = progressStrokeWidth;
    [_circlePathLayer setLineWidth:_progressStrokeWidth];
}

@end
