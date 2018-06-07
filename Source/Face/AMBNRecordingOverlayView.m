#import "AMBNRecordingOverlayView.h"
#import "AMBNCircleButton.h"

@interface AMBNRecordingOverlayView() {
    AMBNRecordingPreviewSizing _recordingPreviewSizing;
}
@property (weak, nonatomic) IBOutlet AMBNCircleButton *cameraButton;
@property (weak, nonatomic) IBOutlet UILabel *topHintLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomHintLabel;
@property (weak, nonatomic) IBOutlet UILabel *recordingHintLabel;
@property (weak, nonatomic) IBOutlet UILabel *capturingLabel;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *topHintLabelTopConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *recordHintLabelBottomConstraint;
@property (nonatomic) CGRect ovalFrame;
@property (nonatomic) CGPoint topHintCenter;
@property (nonatomic) CGPoint recordingHintCenter;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *cameraButtonFrameView;
@end

@implementation AMBNRecordingOverlayView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.recordingHintLabel.hidden = YES;
    self.capturingLabel.text = @"";
    self.cameraButton.enabled = NO;
    _recordingPreviewSizing = AMBNRecordingPreviewSizingCover;
    _ovalFrame = CGRectZero;
}

- (void)drawRect:(CGRect)rect {
    
    //Size helpers
    CGFloat rectWidth = rect.size.width;
    CGFloat rectHeight = rect.size.height;
    CGFloat rectX = rect.origin.x;
    CGFloat rectY = rect.origin.y;
    
    //Background rect
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]));
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rectX, rectY);
    CGContextAddLineToPoint(context, rectX + rectWidth, rectY);
    CGContextAddLineToPoint(context, rectX + rectWidth, rectY + rectHeight);
    CGContextAddLineToPoint(context, rectX, rectY + rectHeight);
    CGContextClosePath(context);
    
    //Oval
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:_ovalFrame cornerRadius:_ovalFrame.size.width/2];
    CGContextAddPath(context, [bezierPath bezierPathByReversingPath].CGPath);
    
    CGContextFillPath(context);
    CGContextRetain(context);
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    [_bottomHintLabel layoutIfNeeded];
    [_topHintLabel layoutIfNeeded];
    [_recordingHintLabel layoutIfNeeded];
   
    CGFloat viewHeight = self.frame.size.height;
    CGFloat bottomSectionHeight = 140 + _bottomHintLabel.frame.size.height;
    CGFloat topSectionHeight = (CGRectGetMaxY(_topHintLabel.frame)) +20;
    CGFloat ovalX = self.frame.size.width * 0.15f;
    CGFloat ovalWidth = self.frame.size.width * 0.7f;

    if (bottomSectionHeight < viewHeight/5) {
        //Top hint label
        _topHintLabelTopConstraint.constant = (bottomSectionHeight - _topHintLabel.frame.size.height) /2;
        //Oval
        CGRect newOvalFrame = CGRectMake(ovalX, bottomSectionHeight, ovalWidth, viewHeight - (bottomSectionHeight * 2));
        self.ovalFrame = newOvalFrame;
        _recordHintLabelBottomConstraint.constant = 15;
    } else if (bottomSectionHeight < viewHeight/3) {
        //Top hint label
        _topHintLabelTopConstraint.constant = (bottomSectionHeight - _topHintLabel.frame.size.height) /2;
        //Oval
        CGRect newOvalFrame = CGRectMake(ovalX, bottomSectionHeight - 20, ovalWidth, viewHeight - (bottomSectionHeight * 2) + 20);
        self.ovalFrame = newOvalFrame;
        _recordHintLabelBottomConstraint.constant = 25;
    }else if (bottomSectionHeight > viewHeight/4) {
        //Oval
        CGRect newOvalFrame = CGRectMake(ovalX, (CGRectGetMaxY(_topHintLabel.frame) + 20), ovalWidth, viewHeight - (topSectionHeight * 2) -20);
        self.ovalFrame = newOvalFrame;
        _recordHintLabelBottomConstraint.constant = 25;
    }
}


- (IBAction)cameraButtonPressed:(id)sender {
    [self.delegate recordButtonPressed];
}

#pragma mark - AMBNRecordingOverlayDelegate

- (void)recordingOverlaySetupWithTopHint:(NSString *)topHint bottomHint:(NSString *)bottomHint recordingHint:(NSString *)recordingHint {
    self.topHintLabel.text = topHint;
    self.bottomHintLabel.text = bottomHint;
    self.recordingHintLabel.text = recordingHint;
}

- (void)recordingOverlayIsReadyToStart {
    self.cameraButton.enabled = YES;
}

- (void)recordingOverlayDidStartRecording {
        [UIView animateWithDuration:0.2 animations:^{
            self.bottomHintLabel.layer.opacity = 0;
        } completion:^(BOOL finished) {
            self.bottomHintLabel.hidden = YES;
            self.recordingHintLabel.hidden = NO;
            [self.recordingHintLabel setFont:[UIFont boldSystemFontOfSize:20]];
            [UIView animateWithDuration:0.2 animations:^{
                self.bottomHintLabel.layer.opacity = 1;
            } completion:^(BOOL finished) {
                self.cameraButton.animating = YES;
            }];
        }];
}

- (void)recordingOverlayDidUpdateDurationLeft:(NSTimeInterval)durationLeft {
    self.capturingLabel.text = [NSString stringWithFormat:@"Capturing\n%isec. left", (int)durationLeft];
}

#pragma mark - AMBNRecordingOverlayDatasource

- (AMBNRecordingPreviewSizing)sizingForRecordingPreview {
    return _recordingPreviewSizing;
}

#pragma mark - Helpers

+ (instancetype)getWithFittedPreview {
    return [[[NSBundle bundleForClass:self.classForCoder] loadNibNamed:@"AMBNRecordingOverlayView" owner:self options:nil] objectAtIndex:0];
}

+ (instancetype)getWithFilledPreview {
    return [[[NSBundle bundleForClass:self.classForCoder] loadNibNamed:@"AMBNRecordingOverlayView" owner:self options:nil] objectAtIndex:0];
}

@end
