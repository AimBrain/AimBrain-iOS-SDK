
#import "AMBNCircleButton.h"


@interface AMBNCircleButton ()

@property (nonatomic, strong) UIView *iconView;

// defaults
- (void)setupDefaults;

// setters
- (void)setAnimating:(BOOL)isAnimating;


@end


@implementation AMBNCircleButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaults];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
    }
    
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    self.layer.cornerRadius = self.bounds.size.width / 2.0;
    
    if (_animating) {
        [self drawProgressCircle:2];
    } else {
        _iconView.layer.cornerRadius = CGRectGetWidth(_iconView.bounds) / 2.0;
    }
}

#pragma mark - defaults

- (void)setupDefaults {
    
    self.backgroundColor =  [UIColor colorWithRed:70/255.0 green:207/255.0 blue:109/255.0 alpha:1.0];
    
    _iconView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    _iconView.backgroundColor = [UIColor whiteColor];
    _iconView.userInteractionEnabled = NO;
    [self addSubview:_iconView];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_iconView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_iconView
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_iconView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:2.0 / 7.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_iconView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_iconView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0.0]];
}

#pragma mark - setters

- (void)setAnimating:(BOOL)isAnimating {
    
    if (_animating == isAnimating) {
        return;
    }
    
    CGFloat newCornerRadius = 0.0f;
    UIColor *newBackgrounColor = _originalBackgroundColor;
    
    if (_animating) {
        newCornerRadius = CGRectGetWidth(_iconView.bounds) / 2.0;
    } else {
        newBackgrounColor = _wavingBackgroundColor;
        [self drawProgressCircle:2];
    }
    _animating = isAnimating;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    
    [super setBackgroundColor:backgroundColor];
    
    _originalBackgroundColor = backgroundColor;
}

- (void)drawProgressCircle:(int) completionTime {
    
    [self setBackgroundColor:[UIColor redColor]];
    
    CGFloat startAngle = 0;
    CGFloat endAngle = 1;
    
    CAShapeLayer* shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    shapeLayer.frame = self.frame;
    shapeLayer.path = [[UIBezierPath bezierPathWithOvalInRect:shapeLayer.bounds] CGPath];
    shapeLayer.lineWidth =5;
    shapeLayer.strokeColor = [[UIColor colorWithRed:223/255.0 green:133/255.0 blue:133/255.0 alpha:1.0] CGColor];
    shapeLayer.strokeStart = startAngle;
    shapeLayer.strokeEnd = endAngle;
    
    // Apply the animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.duration = completionTime;
    drawAnimation.fromValue = [NSNumber numberWithFloat:startAngle];
    drawAnimation.toValue   = [NSNumber numberWithFloat:endAngle];
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [shapeLayer addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
    
    [self.layer addSublayer:shapeLayer];
}

@end
